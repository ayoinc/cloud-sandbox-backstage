/**
 * Registration recorder: stands in front of the catalog's locations API
 * (`/api/catalog/locations`) and keeps the account of every catalog file
 * that is registered through it.
 *
 * The catalog has no place to hang this on: it creates a registered file
 * without telling anyone who asked. So the root HTTP router is customised
 * to pass those requests through this recorder first. It lets each request
 * through to the catalog unchanged, and
 *
 * - when the catalog answers 201 to a registration, files the new address
 *   under the account of the person who asked;
 * - follows an address that is changed, and drops one that is unregistered;
 * - shows a signed-in person only the registered files of their own
 *   accounts: the others are left out of lists and answer 404, as a file
 *   that is not registered does;
 * - shows a portal administrator, besides, the registered files that have
 *   no account, so that somebody can unregister them. Their entities stay
 *   hidden from everyone;
 * - refuses a signed-in person an address whose entries are in the catalog
 *   already from somewhere else, and a wildcard: the catalog would hand
 *   those entries, and so the account they are shown to, to the new file
 *   (see ./catalogModule.ts);
 * - takes from the answer to a dry run the account anything is filed under.
 *
 * Who is asking is read from the bearer token without verifying it. That is
 * safe because nothing here gives anything: the recorder only ever narrows
 * what is asked of the catalog, removes from what it answers, or refuses,
 * and the catalog answers only after it has verified the same token. A
 * token someone made up gets the catalog's 401, or one of the two refusals
 * above, which say no more than that an address is in use.
 *
 * Requests that carry no user (the backend's own plugins) pass untouched,
 * but for the dry run. A file registered that way has no account.
 */

import { rootHttpRouterServiceFactory } from '@backstage/backend-defaults/rootHttpRouter';
import type { LoggerService } from '@backstage/backend-plugin-api';
import { tokenTypes } from '@backstage/plugin-auth-node';
import {
  Router,
  json,
  type NextFunction,
  type Request,
  type RequestHandler,
  type Response,
} from 'express';
import {
  isWildcard,
  locationAccounts,
  type LocationAccounts,
} from './catalogModule';
import {
  ACCOUNT_ANNOTATION,
  directory,
  type Memberships,
  type PortalAdmins,
} from './directory';

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

/** One part of a token (0 the header, 1 the claims), read without verifying. */
function tokenPart(
  token: string,
  index: number,
): Record<string, unknown> | undefined {
  try {
    const part: unknown = JSON.parse(
      Buffer.from(token.split('.')[index] ?? '', 'base64url').toString('utf8'),
    );
    return isRecord(part) ? part : undefined;
  } catch {
    return undefined;
  }
}

/**
 * The user a request is made by or on behalf of, or undefined when it
 * carries none. A person's own token names them in `sub`. A token one
 * plugin sends another on a person's behalf (a template run registering a
 * file, for one) names the plugin in `sub` and carries the person's token
 * in `obo`.
 */
export function userOf(req: Request): string | undefined {
  const header = req.headers.authorization;
  // The same reading of the header as the backend's own.
  const token =
    typeof header === 'string'
      ? header.match(/^Bearer[ ]+(\S+)$/i)?.[1]
      : undefined;
  if (!token) {
    return undefined;
  }
  let claims = tokenPart(token, 1);
  if (tokenPart(token, 0)?.typ === tokenTypes.plugin.typParam) {
    claims =
      typeof claims?.obo === 'string' ? tokenPart(claims.obo, 1) : undefined;
  }
  const sub = claims?.sub;
  return typeof sub === 'string' && /^user:/i.test(sub) ? sub : undefined;
}

/** Whether the catalog will take `?dryRun=` as set: the same reading as its own. */
function isDryRun(value: unknown): boolean {
  return (
    value !== undefined && /^(?:y|yes|true|1|on)$/i.test(String(value).trim())
  );
}

/**
 * An answer in the form the catalog gives its own refusals. The catalog
 * names the address a request was made to without the path it is served
 * under (`/locations/…`, not `/api/catalog/locations/…`), and so does
 * this: an answer that stands for the catalog's must not be told from it.
 */
function refusal(
  req: Request,
  statusCode: number,
  name: string,
  message: string,
) {
  return {
    error: { name, message },
    request: { method: req.method, url: req.url },
    response: { statusCode },
  };
}

/** An id no registered file has: the catalog gives each a random one. */
const NO_LOCATION = '00000000-0000-0000-0000-000000000000';

/**
 * The one spelling of an id that is compared here. The database also takes
 * capitals, braces and missing hyphens for the same id, so any other
 * spelling is not looked up at all.
 */
const LOCATION_ID =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

/**
 * Sets one value of the request's query, for the catalog to read. The
 * server has parsed the query before this; where it keeps the result, that
 * is changed too.
 */
function setQuery(req: Request, name: string, value: string): void {
  const at = req.url.indexOf('?');
  const params = new URLSearchParams(at < 0 ? '' : req.url.slice(at + 1));
  params.set(name, value);
  req.url = `${at < 0 ? req.url : req.url.slice(0, at)}?${params}`;
  const parsed: unknown = req.query;
  if (isRecord(parsed)) {
    parsed[name] = value;
  }
}

/** An entity of a dry run, without the account it would be filed under. */
function withoutAccount(entity: unknown): unknown {
  if (
    !isRecord(entity) ||
    !isRecord(entity.metadata) ||
    !isRecord(entity.metadata.annotations)
  ) {
    return entity;
  }
  return {
    ...entity,
    metadata: {
      ...entity.metadata,
      annotations: Object.fromEntries(
        Object.entries(entity.metadata.annotations).filter(
          ([name]) => name.toLowerCase() !== ACCOUNT_ANNOTATION,
        ),
      ),
    },
  };
}

/**
 * Passes what the catalog answers with `status` through `rewrite` before it
 * is sent. An answer that does not come as JSON cannot be checked, and is
 * refused instead of being sent as it is.
 */
function rewriteAnswer(
  res: Response,
  rewrite: (body: unknown) => unknown,
  status = 200,
) {
  const sendJson = res.json.bind(res);
  const write = res.write.bind(res);
  const end = res.end.bind(res);
  let checked = false;
  const refuseUnchecked = () => {
    if (!checked && res.statusCode === status) {
      throw new Error('The catalog answered in a form that cannot be checked');
    }
  };
  res.json = body => {
    const answer = res.statusCode === status ? rewrite(body) : body;
    checked = true;
    return sendJson(answer);
  };
  res.write = ((...args: Parameters<typeof write>) => {
    refuseUnchecked();
    return write(...args);
  }) as typeof res.write;
  res.end = ((...args: Parameters<typeof end>) => {
    refuseUnchecked();
    return end(...args);
  }) as typeof res.end;
}

/** Resolves when the response has been sent, or given up on. */
function answered(res: Response): Promise<void> {
  return new Promise(resolve => {
    res.once('finish', resolve);
    res.once('close', resolve);
  });
}

/**
 * Narrows a `by-query` request to the registered files at `targets`,
 * whatever it asked for. The catalog reads the query from the cursor when
 * there is one, so the cursor is rewritten too.
 */
function narrowQuery(body: unknown, targets: string[]): unknown {
  const own = { type: 'url', target: { $in: targets } };
  const narrow = (query: unknown) =>
    query === undefined ? own : { $all: [query, own] };
  if (!isRecord(body)) {
    return { query: own };
  }
  if (body.cursor === undefined) {
    return { ...body, query: narrow(body.query) };
  }
  if (typeof body.cursor !== 'string') {
    // Not a cursor the catalog accepts: it refuses the request itself.
    return body;
  }
  let cursor: unknown;
  try {
    cursor = JSON.parse(Buffer.from(body.cursor, 'base64').toString('utf8'));
  } catch {
    return body;
  }
  if (!isRecord(cursor)) {
    return body;
  }
  return {
    cursor: Buffer.from(
      JSON.stringify({ ...cursor, query: narrow(cursor.query) }),
      'utf8',
    ).toString('base64'),
  };
}

export interface RegistrationRecorderOptions {
  /** The accounts of registered files; throws until the catalog has started. */
  accounts: () => LocationAccounts;
  memberships: Memberships;
  admins: Pick<PortalAdmins, 'isPortalAdmin'>;
  logger: Pick<LoggerService, 'error'>;
}

/** The recorder, as a router for the catalog's path (`/api/catalog`). */
export interface RegistrationRecorder {
  /** The catalog's own routes for registered files. */
  router: Router;
  /**
   * Resolves when everything the recorder does after a response has gone
   * out is done, for tests.
   */
  settled(): Promise<void>;
}

export function createRegistrationRecorder(
  options: RegistrationRecorderOptions,
): RegistrationRecorder {
  const { accounts, memberships, admins, logger } = options;
  const router = Router();

  const pending = new Set<Promise<void>>();
  function track(work: Promise<void>): Promise<void> {
    pending.add(work);
    const forget = () => pending.delete(work);
    work.then(forget, forget);
    return work;
  }

  // The catalog reads the body again after this. Its parser leaves a body
  // alone when the request is marked as already read, so the mark is set
  // here for both generations of the parser.
  const parseJson = json();
  const readBody: RequestHandler = (req, res, next) =>
    parseJson(req, res, error => {
      if (!error) {
        Object.assign(req, { _body: true });
      }
      next(error);
    });

  const guarded =
    (
      handler: (
        req: Request,
        res: Response,
        next: NextFunction,
      ) => Promise<void>,
    ): RequestHandler =>
    (req, res, next) => {
      track(handler(req, res, next)).catch(next);
    };

  /**
   * The addresses of the registered files `user` may see: those of their
   * accounts and, with `unclaimed`, those without an account when the user
   * is a portal administrator.
   */
  async function targetsOf(
    user: string,
    unclaimed = true,
  ): Promise<Set<string>> {
    const { store } = accounts();
    const own = new Set(
      await store.targetsOf(await memberships.accountsOf(user)),
    );
    if (unclaimed) {
      // Not an administrator when that cannot be told: the directory
      // throws, not rejects, while the portal starts.
      let isAdmin = false;
      try {
        isAdmin = await admins.isPortalAdmin(user, []);
      } catch {
        isAdmin = false;
      }
      if (isAdmin) {
        for (const target of await store.unclaimedTargets()) {
          own.add(target);
        }
      }
    }
    return own;
  }

  const isOwn = (location: unknown, own: Set<string>) =>
    isRecord(location) &&
    location.type === 'url' &&
    typeof location.target === 'string' &&
    own.has(location.target);

  // One registration of an address at a time, so that of two people
  // registering the same file at once, the one the catalog turns down
  // cannot be taken for the one who registered it.
  const turns = new Map<string, Promise<void>>();
  function inTurn(target: string, work: () => Promise<void>): void {
    const turn = track((turns.get(target) ?? Promise.resolve()).then(work));
    turns.set(target, turn);
    turn.finally(() => {
      if (turns.get(target) === turn) {
        turns.delete(target);
      }
    });
  }

  /**
   * Why a signed-in person may not register a file at `target`, or move
   * one there, if so. An address that is registered already is left to the
   * catalog, which refuses it itself.
   */
  async function refusalOf(req: Request, target: string) {
    const { store } = accounts();
    if (await store.isRegistered(target)) {
      return undefined;
    }
    if (isWildcard(target)) {
      return refusal(
        req,
        400,
        'InputError',
        'An address with a wildcard cannot be registered; register each catalog file by its own address',
      );
    }
    // The catalog would hand the entries read from the address to the new
    // file, and with them the account they are shown to.
    if (await store.heldElsewhere(target)) {
      return refusal(
        req,
        409,
        'ConflictError',
        `The entries of url:${target} are in the catalog already`,
      );
    }
    return undefined;
  }

  // Register a file. Recorded only when the catalog has created it: 201,
  // and not registered before, since the catalog also answers 201 for a
  // file that already was when asked to refresh it.
  router.post(
    '/locations',
    readBody,
    guarded(async (req, res, next) => {
      const body = isRecord(req.body) ? req.body : {};
      const target =
        body.type === 'url' && typeof body.target === 'string'
          ? body.target
          : undefined;
      const user = userOf(req);
      const { store, refresh } = accounts();

      if (isDryRun(req.query.dryRun)) {
        // A dry run answers with the entities the file would give. They
        // never say which account anything is filed under, and a file
        // registered to another account is not said to be registered.
        const hidden =
          user !== undefined &&
          target !== undefined &&
          (await store.isRegistered(target)) &&
          !(await targetsOf(user)).has(target);
        rewriteAnswer(
          res,
          answer =>
            isRecord(answer)
              ? {
                  ...answer,
                  ...(hidden ? { exists: false } : {}),
                  entities: Array.isArray(answer.entities)
                    ? answer.entities.map(withoutAccount)
                    : [],
                }
              : {},
          201,
        );
        next();
        return;
      }
      if (target === undefined) {
        next();
        return;
      }
      inTurn(target, async () => {
        let isNew: boolean;
        try {
          isNew = !(await store.isRegistered(target));
          if (isNew) {
            const refused = user ? await refusalOf(req, target) : undefined;
            if (refused) {
              res.status(refused.response.statusCode).json(refused);
              return;
            }
            await store.forget(target);
          } else if (user && !(await targetsOf(user)).has(target)) {
            // Registered, and not the caller's: the catalog must refuse it
            // as taken, and not hand the file back as it does when asked
            // to refresh one that exists.
            setQuery(req, 'onConflict', 'reject');
          }
        } catch (error) {
          next(error);
          return;
        }
        const done = answered(res);
        next();
        await done;
        if (!isNew || !user || res.statusCode !== 201) {
          return;
        }
        try {
          await store.claim(target, await memberships.accountFor(user));
          await refresh(target);
        } catch (error) {
          // Left without an account, the file is shown to no one.
          logger.error(
            `Could not record who registered ${target}`,
            error as Error,
          );
        }
      });
    }),
  );

  // List registered files.
  router.get(
    '/locations',
    guarded(async (req, res, next) => {
      const user = userOf(req);
      if (user) {
        const own = await targetsOf(user);
        rewriteAnswer(res, body =>
          Array.isArray(body)
            ? body.filter(item => isRecord(item) && isOwn(item.data, own))
            : [],
        );
      }
      next();
    }),
  );

  router.post(
    '/locations/by-query',
    readBody,
    guarded(async (req, res, next) => {
      const user = userOf(req);
      if (user) {
        const own = await targetsOf(user);
        req.body = narrowQuery(req.body, [...own]);
        // The catalog compares addresses without regard to case; this
        // keeps to the exact ones.
        rewriteAnswer(res, body =>
          isRecord(body) && Array.isArray(body.items)
            ? { ...body, items: body.items.filter(item => isOwn(item, own)) }
            : {},
        );
      }
      next();
    }),
  );

  // The registered file an entity comes from.
  router.get(
    '/locations/by-entity/:kind/:namespace/:name',
    guarded(async (req, res, next) => {
      const user = userOf(req);
      if (user) {
        const own = await targetsOf(user);
        const { kind, namespace, name } = req.params;
        rewriteAnswer(res, body => {
          if (isOwn(body, own)) {
            return body;
          }
          res.status(404);
          return refusal(
            req,
            404,
            'NotFoundError',
            `found no entity for ref ${`${kind}:${namespace}/${name}`.toLowerCase()}`,
          );
        });
      }
      next();
    }),
  );

  // One registered file: read it, change its address, unregister it.
  const one = guarded(async (req, res, next) => {
    const user = userOf(req);
    if (!user && req.method === 'GET') {
      next();
      return;
    }
    const asked = String(req.params.id);
    // The catalog is asked for a file that does not exist instead, so that
    // it checks the caller as for any request and then answers that there
    // is none; its answer names the id asked for.
    const passAsMissing = () => {
      const query = req.url.indexOf('?');
      req.url = `/locations/${NO_LOCATION}${
        query < 0 ? '' : req.url.slice(query)
      }`;
      const sendJson = res.json.bind(res);
      res.json = body =>
        sendJson(
          JSON.parse(JSON.stringify(body).replaceAll(NO_LOCATION, asked)),
        );
      next();
    };
    if (user && !LOCATION_ID.test(asked)) {
      passAsMissing();
      return;
    }
    const { store } = accounts();
    const location = await store.locationById(asked);
    if (!location) {
      next();
      return;
    }
    // Changing the address of a file without an account stays with nobody.
    const own = user ? await targetsOf(user, req.method !== 'PUT') : undefined;
    if (own && !isOwn(location, own)) {
      passAsMissing();
      return;
    }
    if (user && req.method === 'PUT') {
      const { type, target } = isRecord(req.body) ? req.body : {};
      const refused =
        type === 'url' && typeof target === 'string'
          ? await refusalOf(req, target)
          : undefined;
      if (refused) {
        res.status(refused.response.statusCode).json(refused);
        return;
      }
    }
    if (location.type !== 'url' || req.method === 'GET') {
      next();
      return;
    }

    const done = answered(res);
    next();
    await done;
    try {
      if (req.method === 'DELETE' && res.statusCode === 204) {
        await store.forget(location.target);
      } else if (req.method === 'PUT' && res.statusCode === 200) {
        const { type, target } = isRecord(req.body) ? req.body : {};
        await store.retarget(
          location.target,
          type === 'url' && typeof target === 'string' ? target : undefined,
        );
      }
    } catch (error) {
      logger.error(
        `Could not follow the change to ${location.target}`,
        error as Error,
      );
    }
  });
  router.get('/locations/:id', one);
  router.put('/locations/:id', readBody, one);
  router.delete('/locations/:id', one);

  return {
    router,
    async settled() {
      while (pending.size > 0) {
        await Promise.allSettled([...pending]);
      }
    },
  };
}

/**
 * Puts the recorder in front of the catalog's API in the backend's `app`.
 *
 * The recorder answers some requests itself, and its router answers any
 * OPTIONS request to one of its paths, so the security headers and the
 * cross-origin answer come before it: without them an app served from
 * another origin than the backend could not register, list or unregister
 * a file, its preflight request being answered without leave. For a
 * request that goes on to the catalog the backend sets the same headers
 * once more.
 */
export function mountRecorder(
  app: { use(path: string, ...handlers: unknown[]): unknown },
  middleware: { helmet(): unknown; cors(): unknown },
  recorder: RequestHandler,
): void {
  app.use('/api/catalog', middleware.helmet(), middleware.cors(), recorder);
}

/**
 * The backend's root HTTP router, with the recorder in front of the
 * catalog's locations API and everything else as it is by default.
 */
export default rootHttpRouterServiceFactory({
  configure({ app, middleware, logger, applyDefaults }) {
    mountRecorder(
      app,
      middleware,
      createRegistrationRecorder({
        accounts: locationAccounts,
        memberships: directory,
        admins: directory,
        logger,
      }).router,
    );
    applyDefaults();
  },
});
