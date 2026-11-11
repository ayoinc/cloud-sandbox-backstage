/**
 * Organisations routes, version 2. The Cloudflare deployment serves the same
 * API; what a request may contain and how it is refused is in rules.ts,
 * which both read.
 *
 * Public (the sign-in page needs them):
 * - GET    /:slug                     - The organisation
 * - GET    /:slug/logo/:kind          - Its full or icon logo
 *
 * Signed in:
 * - GET    /                          - The caller's organisation, role and invitations
 * - GET    /?scope=portal             - Every organisation (portal administrator)
 * - POST   /                          - Create an organisation (not the guest)
 * - PATCH  /:slug                     - Change name, address, colour, theme (owner)
 * - PUT    /:slug/logo/:kind          - Upload one logo, as the request body (owner)
 * - DELETE /:slug/logo/:kind          - Remove one logo (owner)
 * - DELETE /:slug                     - Delete the organisation (owner, or a
 *                                       portal administrator)
 * - GET    /:slug/members             - Members and invitations (any member)
 * - POST   /:slug/members             - Invite a person (owner)
 * - POST   /:slug/join                - Take up the caller's invitation
 * - DELETE /:slug/members/:entityRef  - Remove a member or an invitation
 *                                       (owner, or the person themself)
 */

import { Router, raw, Request, Response, RequestHandler } from 'express';
import type { Knex } from 'knex';
import type {
  HttpAuthService,
  LoggerService,
  UserInfoService,
} from '@backstage/backend-plugin-api';
import { directory, organisationAccount } from '../accounts/directory';
import {
  ApiError,
  GUEST_USER,
  MAX_BODY_BYTES,
  MAX_LOGO_BYTES,
  checkLogo,
  logoHeaders,
  readJson,
  readChanges,
  readLogoKind,
  readLogoType,
  readName,
  readRole,
  readSlug,
  readUserRef,
  refusals,
  type Role,
} from './rules';
import {
  createOrganisation,
  deleteLogo,
  deleteOrganisation,
  findMembership,
  findOrganisation,
  invite,
  join,
  listInvitations,
  listMembers,
  listOrganisations,
  listReceivedInvitations,
  readLogo,
  remove,
  saveLogo,
  updateOrganisation,
} from './database';

interface RouterDeps {
  knex: Knex;
  logger: LoggerService;
  httpAuth: HttpAuthService;
  userInfo: UserInfoService;
}

// Bodies are read as they were sent, whatever the request says their type
// is, and no further than the limit: rules.ts decides what they hold.
const readUpTo = (limit: number) =>
  raw({ type: () => true, limit, inflate: false });
const parseJson = readUpTo(MAX_BODY_BYTES);
const parseLogo = readUpTo(MAX_LOGO_BYTES);

/**
 * The bytes of the request body, read with `parser`. Called from inside a
 * route, once the caller has been checked, so that nobody is told about
 * their body before being told they may not send one.
 */
function receive(
  parser: RequestHandler,
  req: Request,
  res: Response,
  refusalFor: Record<string, (() => ApiError) | undefined>,
): Promise<Uint8Array> {
  // The executor form: this project compiles for a library without
  // Promise.withResolvers.
  return new Promise((resolve, reject) => {
    parser(req, res, (error?: unknown) => {
      if (!error) {
        // Without a body the parser leaves nothing: rules.ts says what an
        // empty one is worth.
        resolve(new Uint8Array(Buffer.isBuffer(req.body) ? req.body : []));
        return;
      }
      // body-parser names what went wrong in `type`.
      const type =
        typeof error === 'object' && 'type' in error ? String(error.type) : '';
      reject(refusalFor[type]?.() ?? error);
    });
  });
}

const receiveJson = async (req: Request, res: Response) =>
  readJson(
    await receive(parseJson, req, res, {
      'entity.too.large': refusals.bodyTooLarge,
      // A compressed body is not a JSON object.
      'encoding.unsupported': refusals.badBody,
    }),
  );

const receiveLogo = (req: Request, res: Response) =>
  receive(parseLogo, req, res, {
    'entity.too.large': refusals.logoTooLarge,
    'encoding.unsupported': refusals.logoType,
  });

export function createRouter(deps: RouterDeps): Router {
  const { knex, logger, httpAuth, userInfo } = deps;
  const router = Router();

  /**
   * Answers a refusal as `{ error: message }`. Anything else, a missing
   * token included, is the framework's to answer.
   */
  const handle =
    (handler: (req: Request, res: Response) => Promise<void>): RequestHandler =>
    async (req, res, next) => {
      try {
        await handler(req, res);
      } catch (error) {
        if (error instanceof ApiError) {
          res.status(error.status).json({ error: error.message });
          return;
        }
        next(error);
      }
    };

  /**
   * The signed-in caller: their user ref and the refs their token names,
   * lower-case. Throws without a user token.
   */
  async function identityOf(
    req: Request,
  ): Promise<{ userRef: string; ownershipRefs: string[] }> {
    // Backstage types its services against Express 4; this is Express 5.
    const request = req as unknown as Parameters<
      HttpAuthService['credentials']
    >[0];
    const credentials = await httpAuth.credentials(request, {
      allow: ['user'],
    });
    const { userEntityRef, ownershipEntityRefs } = await userInfo.getUserInfo(
      credentials,
    );
    return {
      userRef: userEntityRef.toLowerCase(),
      ownershipRefs: ownershipEntityRefs.map(ref => ref.toLowerCase()),
    };
  }

  const callerOf = async (req: Request) => (await identityOf(req)).userRef;

  /** The organisation in the address, as it is now. */
  async function organisationOf(slug: string) {
    const organisation = await findOrganisation(knex, slug);
    if (!organisation) {
      throw refusals.noOrganisation();
    }
    return organisation;
  }

  /**
   * The caller and the slug in the address, once the caller is signed in,
   * the organisation exists and, when `needed` is given, the caller holds
   * that role in it: in that order. Where a portal administrator will do
   * as well, one is let through whatever their role.
   */
  async function authorise(
    req: Request,
    needed?: Role | 'owner or administrator',
  ): Promise<{ slug: string; userRef: string }> {
    const { userRef, ownershipRefs } = await identityOf(req);
    const { slug } = await organisationOf(String(req.params.slug));
    if (needed) {
      const membership = await findMembership(knex, userRef);
      let refusal: (() => ApiError) | undefined;
      if (membership?.slug !== slug) {
        refusal = refusals.notMember;
      } else if (needed !== 'member' && membership.role !== 'owner') {
        refusal = refusals.notOwner;
      }
      if (
        refusal &&
        !(
          needed === 'owner or administrator' &&
          (await directory.isPortalAdmin(userRef, ownershipRefs))
        )
      ) {
        throw refusal();
      }
    }
    return { slug, userRef };
  }

  const sendOrganisation = async (
    res: Response,
    slug: string,
    status = 200,
  ) => {
    res.status(status).json(await organisationOf(slug));
  };

  const sendMembers = async (res: Response, slug: string) => {
    res.json({
      members: await listMembers(knex, slug),
      invitations: await listInvitations(knex, slug),
    });
  };

  // GET / - The caller's organisation, role and invitations. With
  // ?scope=portal, every organisation on the portal (portal administrator).
  router.get(
    '/',
    handle(async (req, res) => {
      const { userRef, ownershipRefs } = await identityOf(req);
      if (req.query.scope === 'portal') {
        if (!(await directory.isPortalAdmin(userRef, ownershipRefs))) {
          throw refusals.notPortalAdmin();
        }
        res.json({ organisations: await listOrganisations(knex) });
        return;
      }
      const membership = await findMembership(knex, userRef);
      const organisation = membership
        ? (await findOrganisation(knex, membership.slug)) ?? null
        : null;
      res.json({
        organisation,
        role: organisation && membership ? membership.role : null,
        userEntityRef: userRef,
        canCreate: userRef !== GUEST_USER && !membership,
        invitations: await listReceivedInvitations(knex, userRef),
      });
    }),
  );

  // POST / - Create an organisation; the caller becomes its owner
  router.post(
    '/',
    handle(async (req, res) => {
      const userRef = await callerOf(req);
      if (userRef === GUEST_USER) {
        throw refusals.guest();
      }
      const body = await receiveJson(req, res);
      const name = readName(body.name);
      const slug = readSlug(body.slug);
      await createOrganisation(knex, { slug, name }, userRef);
      logger.info(`Organisation ${slug} created by ${userRef}`);
      await sendOrganisation(res, slug, 201);
    }),
  );

  // GET /:slug - The organisation (public)
  router.get(
    '/:slug',
    handle(async (req, res) => {
      const organisation = await organisationOf(String(req.params.slug));
      res.set('cache-control', 'no-store').json(organisation);
    }),
  );

  // PATCH /:slug - Change name, address, colour or theme (owner). The
  // answer is the organisation at the address it then has.
  router.patch(
    '/:slug',
    handle(async (req, res) => {
      const { slug, userRef } = await authorise(req, 'owner');
      const address = await updateOrganisation(
        knex,
        slug,
        readChanges(await receiveJson(req, res)),
      );
      if (address !== slug) {
        logger.info(`Organisation ${slug} moved to ${address} by ${userRef}`);
      }
      await sendOrganisation(res, address);
    }),
  );

  // DELETE /:slug - Delete the organisation with all that belongs to it
  // (owner, or a portal administrator). The catalog files registered under
  // it pass to its longest-standing owner.
  router.delete(
    '/:slug',
    handle(async (req, res) => {
      const { slug, userRef } = await authorise(req, 'owner or administrator');
      await deleteOrganisation(knex, slug, (id, owner) =>
        directory.moveAccount(organisationAccount(id), owner),
      );
      logger.info(`Organisation ${slug} deleted by ${userRef}`);
      res.status(204).end();
    }),
  );

  // GET /:slug/logo/:kind - A logo (public)
  router.get(
    '/:slug/logo/:kind',
    handle(async (req, res) => {
      const kind = readLogoKind(String(req.params.kind));
      const logo = await readLogo(knex, String(req.params.slug), kind);
      if (!logo) {
        throw refusals.noLogo();
      }
      const { v } = req.query;
      res
        .set(
          logoHeaders(
            logo.type,
            logo.updatedAt,
            typeof v === 'string' ? v : undefined,
          ),
        )
        .send(logo.bytes);
    }),
  );

  // PUT /:slug/logo/:kind - Upload one logo; the body is the image (owner)
  router.put(
    '/:slug/logo/:kind',
    handle(async (req, res) => {
      const { slug } = await authorise(req, 'owner');
      const kind = readLogoKind(String(req.params.kind));
      const bytes = await receiveLogo(req, res);
      const type = readLogoType(req.headers['content-type']);
      checkLogo(type, bytes);
      await saveLogo(knex, slug, kind, { type, bytes: Buffer.from(bytes) });
      await sendOrganisation(res, slug);
    }),
  );

  // DELETE /:slug/logo/:kind - Remove one logo (owner)
  router.delete(
    '/:slug/logo/:kind',
    handle(async (req, res) => {
      const { slug } = await authorise(req, 'owner');
      await deleteLogo(knex, slug, readLogoKind(String(req.params.kind)));
      await sendOrganisation(res, slug);
    }),
  );

  // GET /:slug/members - Members and invitations (any member)
  router.get(
    '/:slug/members',
    handle(async (req, res) => {
      const { slug } = await authorise(req, 'member');
      await sendMembers(res, slug);
    }),
  );

  // POST /:slug/members - Invite a person; they join when they accept (owner)
  router.post(
    '/:slug/members',
    handle(async (req, res) => {
      const { slug, userRef } = await authorise(req, 'owner');
      const body = await receiveJson(req, res);
      const person = {
        userRef: readUserRef(body.entityRef),
        role: readRole(body.role),
      };
      await invite(knex, slug, person, userRef);
      await sendMembers(res, slug);
    }),
  );

  // POST /:slug/join - Take up the caller's invitation
  router.post(
    '/:slug/join',
    handle(async (req, res) => {
      const { slug, userRef } = await authorise(req);
      await join(knex, slug, userRef);
      await sendOrganisation(res, slug);
    }),
  );

  // DELETE /:slug/members/:entityRef - Remove a member or an invitation.
  // An owner removes anyone; anyone removes themself, which is how a member
  // leaves and how a person invited declines.
  router.delete(
    '/:slug/members/:entityRef',
    handle(async (req, res) => {
      const { slug, userRef } = await authorise(req);
      // Who may is settled before what was asked for is looked at, so a
      // caller who is not allowed is told that whatever they sent.
      let target: string | undefined;
      let invalid: unknown;
      try {
        target = readUserRef(String(req.params.entityRef));
      } catch (error) {
        invalid = error;
      }
      if (target !== userRef) {
        await authorise(req, 'owner');
      }
      if (target === undefined) {
        throw invalid;
      }
      await remove(knex, slug, target);
      res.status(204).end();
    }),
  );

  return router;
}
