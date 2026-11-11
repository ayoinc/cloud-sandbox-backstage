/**
 * Organisations backend plugin: each signed-in user can create an
 * organisation with its own address (slug), name, logos and theme, and
 * invite people to it. Served at /api/organisations; routes.ts lists the
 * endpoints. Organisations, members, invitations and logo files live in the
 * plugin's database.
 */

import {
  createBackendPlugin,
  coreServices,
} from '@backstage/backend-plugin-api';
import { organisationAccount, provide } from '../accounts/directory';
import { findOrganisationId, initializeTables } from './database';
import { createRouter } from './routes';

export const organisationsPlugin = createBackendPlugin({
  pluginId: 'organisations',
  register(env) {
    env.registerInit({
      deps: {
        httpRouter: coreServices.httpRouter,
        logger: coreServices.logger,
        database: coreServices.database,
        httpAuth: coreServices.httpAuth,
        userInfo: coreServices.userInfo,
      },
      async init({ httpRouter, logger, database, httpAuth, userInfo }) {
        const knex = await database.getClient();
        await initializeTables(knex, logger);

        // What the other plugins ask to keep one account's things from
        // another's: a person's own account, and their organisation's when
        // they are in one.
        const accountOf = async (userRef: string) => {
          const own = userRef.toLowerCase();
          const id = await findOrganisationId(knex, own);
          return { own, organisation: id && organisationAccount(id) };
        };
        provide({
          async accountsOf(userRef) {
            const { own, organisation } = await accountOf(userRef);
            return organisation ? [own, organisation] : [own];
          },
          async accountFor(userRef) {
            const { own, organisation } = await accountOf(userRef);
            return organisation || own;
          },
        });

        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        httpRouter.use(
          createRouter({ knex, logger, httpAuth, userInfo }) as any,
        );
        // The sign-in page shows an organisation's name and logo before
        // anyone has signed in, at addresses that start with its slug, so
        // no path can be named here. Every other route checks who is
        // calling itself.
        httpRouter.addAuthPolicy({
          path: '/',
          allow: 'unauthenticated',
        });
      },
    });
  },
});

export default organisationsPlugin;
