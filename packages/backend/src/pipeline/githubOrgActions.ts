/*
 * Template actions that manage the people of a GitHub organisation: create a
 * team, add a user to a team, invite a user.
 *
 * They call GitHub's REST API with the credentials of the GitHub integration,
 * the same ones `publish:github` creates repositories with. Those credentials
 * must be allowed to administer the organisation: for a personal access token
 * that is the `admin:org` scope, held by an owner of the organisation.
 *
 * In a dry run nothing is sent to GitHub: each action logs what it would do.
 */

import {
  coreServices,
  createBackendModule,
} from '@backstage/backend-plugin-api';
import {
  DefaultGithubCredentialsProvider,
  GithubCredentialsProvider,
  ScmIntegrations,
} from '@backstage/integration';
import {
  createTemplateAction,
  scaffolderActionsExtensionPoint,
} from '@backstage/plugin-scaffolder-node';

const GITHUB_HOST = 'github.com';
const ORG_DESCRIPTION = 'The GitHub organisation, e.g. `my-org`';

type OrgApi = {
  integrations: ScmIntegrations;
  credentials: GithubCredentialsProvider;
};

/** One entry of the `errors` list of a failed answer, as text. */
function errorDetail(error: unknown): unknown {
  if (typeof error !== 'object' || error === null) {
    return error;
  }
  return (
    ('message' in error && error.message) || ('code' in error && error.code)
  );
}

/** What GitHub says went wrong, from the body of a failed answer. */
function failureReason(text: string): string {
  let body: unknown;
  try {
    body = JSON.parse(text);
  } catch {
    body = undefined;
  }
  const parts: unknown[] = [];
  if (typeof body === 'object' && body !== null) {
    if ('message' in body) {
      parts.push(body.message);
    }
    if ('errors' in body && Array.isArray(body.errors)) {
      const errors: unknown[] = body.errors;
      parts.push(...errors.map(errorDetail));
    }
  }
  const reason = parts
    .filter(part => typeof part === 'string' && part !== '')
    .join('; ');
  // Not the JSON GitHub normally answers with: show the start of what came.
  return reason || text.slice(0, 500);
}

/**
 * Calls GitHub's REST API as the integration, on behalf of an organisation,
 * and returns the parsed answer. `path` starts after `/orgs/<org>`.
 */
async function orgRequest<T>(
  { integrations, credentials }: OrgApi,
  org: string,
  method: 'GET' | 'POST' | 'PUT',
  path: string,
  body?: object,
): Promise<T> {
  const apiBaseUrl = integrations.github.byHost(GITHUB_HOST)?.config.apiBaseUrl;
  if (!apiBaseUrl) {
    throw new Error(`No GitHub integration is configured for ${GITHUB_HOST}`);
  }
  const { headers } = await credentials.getCredentials({
    url: `https://${GITHUB_HOST}/${encodeURIComponent(org)}`,
  });
  if (!headers) {
    throw new Error(
      `The GitHub integration for ${GITHUB_HOST} has no token or app to act as`,
    );
  }
  const response = await fetch(
    `${apiBaseUrl}/orgs/${encodeURIComponent(org)}${path}`,
    {
      method,
      headers: {
        ...headers,
        accept: 'application/vnd.github+json',
        'x-github-api-version': '2022-11-28',
        ...(body && { 'content-type': 'application/json' }),
      },
      body: body && JSON.stringify(body),
    },
  );
  const text = await response.text();
  if (!response.ok) {
    const reason = failureReason(text);
    // GitHub answers 404, not 403, to credentials that may not see the
    // organisation's settings.
    const hint =
      response.status === 403 || response.status === 404
        ? ` Check that ${org} and the names given exist, and that the portal's GitHub credentials may administer the organisation (a token needs the admin:org scope and an owner of ${org}).`
        : '';
    throw new Error(
      `GitHub answered ${response.status} to ${method} /orgs/${org}${path}: ${reason}.${hint}`,
    );
  }
  return JSON.parse(text);
}

function createTeamAction(api: OrgApi) {
  return createTemplateAction({
    id: 'github:team:create',
    description: 'Creates a team in a GitHub organisation.',
    supportsDryRun: true,
    schema: {
      input: {
        org: z => z.string({ description: ORG_DESCRIPTION }),
        name: z => z.string({ description: 'The name of the team' }),
        description: z =>
          z.string({ description: 'What the team is for' }).optional(),
        privacy: z =>
          z
            .enum(['closed', 'secret'], {
              description:
                '`closed`: every member of the organisation sees the team. `secret`: only its members do. GitHub uses `closed` when not set.',
            })
            .optional(),
        notificationSetting: z =>
          z
            .enum(['notifications_enabled', 'notifications_disabled'], {
              description:
                'Whether members are notified when the team is mentioned. GitHub uses `notifications_enabled` when not set.',
            })
            .optional(),
      },
      output: {
        slug: z =>
          z.string({ description: 'The slug GitHub gave the team' }).optional(),
        url: z =>
          z
            .string({ description: 'The page of the team on GitHub' })
            .optional(),
      },
    },
    async handler(ctx) {
      const { org, name, description, privacy, notificationSetting } =
        ctx.input;
      if (ctx.isDryRun) {
        ctx.logger.info(
          `Dry run: would create the team "${name}" in ${org} (privacy ${
            privacy ?? 'closed'
          }, ${notificationSetting ?? 'notifications_enabled'})`,
        );
        return;
      }
      const team = await orgRequest<{ slug: string; html_url: string }>(
        api,
        org,
        'POST',
        '/teams',
        {
          name,
          description,
          privacy,
          notification_setting: notificationSetting,
        },
      );
      ctx.logger.info(`Created the team ${team.html_url}`);
      ctx.output('slug', team.slug);
      ctx.output('url', team.html_url);
    },
  });
}

function addTeamMemberAction(api: OrgApi) {
  return createTemplateAction({
    id: 'github:team:member:add',
    description:
      'Adds a user to a team of a GitHub organisation, or changes the role of a member. A user who is not in the organisation yet is invited to it.',
    supportsDryRun: true,
    schema: {
      input: {
        org: z => z.string({ description: ORG_DESCRIPTION }),
        teamSlug: z => z.string({ description: 'The slug of the team' }),
        username: z => z.string({ description: 'The GitHub user to add' }),
        role: z =>
          z
            .enum(['member', 'maintainer'], {
              description:
                'The role in the team. GitHub uses `member` when not set.',
            })
            .optional(),
      },
    },
    async handler(ctx) {
      const { org, teamSlug, username, role } = ctx.input;
      if (ctx.isDryRun) {
        ctx.logger.info(
          `Dry run: would add ${username} to the team ${teamSlug} of ${org} as ${
            role ?? 'member'
          }`,
        );
        return;
      }
      const membership = await orgRequest<{ state: string; role: string }>(
        api,
        org,
        'PUT',
        `/teams/${encodeURIComponent(
          teamSlug,
        )}/memberships/${encodeURIComponent(username)}`,
        { role },
      );
      ctx.logger.info(
        membership.state === 'pending'
          ? `${username} is not a member of ${org} yet and was invited; they join the team ${teamSlug} as ${membership.role} on accepting`
          : `${username} is now ${membership.role} of the team ${teamSlug} of ${org}`,
      );
    },
  });
}

function createInvitationAction(api: OrgApi) {
  return createTemplateAction({
    id: 'github:org:invitation:create',
    description:
      'Invites a person to a GitHub organisation by email, optionally into teams.',
    supportsDryRun: true,
    schema: {
      input: {
        org: z => z.string({ description: ORG_DESCRIPTION }),
        email: z =>
          z.string({ description: 'The email address the invitation goes to' }),
        role: z =>
          z
            .enum(['direct_member', 'admin', 'billing_manager'], {
              description:
                'The role in the organisation. GitHub uses `direct_member` when not set.',
            })
            .optional(),
        teamSlugs: z =>
          z
            .array(z.string(), {
              description:
                'Slugs of the teams the person joins on accepting the invitation',
            })
            .optional(),
      },
    },
    async handler(ctx) {
      const { org, email, role, teamSlugs = [] } = ctx.input;
      const into =
        teamSlugs.length > 0 ? `, into the teams ${teamSlugs.join(', ')}` : '';
      if (ctx.isDryRun) {
        ctx.logger.info(
          `Dry run: would invite ${email} to ${org} as ${
            role ?? 'direct_member'
          }${into}`,
        );
        return;
      }
      // An invitation names teams by number; people know them by slug.
      const teamIds: number[] = [];
      for (const slug of teamSlugs) {
        const team = await orgRequest<{ id: number }>(
          api,
          org,
          'GET',
          `/teams/${encodeURIComponent(slug)}`,
        );
        teamIds.push(team.id);
      }
      await orgRequest(api, org, 'POST', '/invitations', {
        email,
        role,
        team_ids: teamIds,
      });
      ctx.logger.info(`Invited ${email} to ${org}${into}`);
    },
  });
}

export default createBackendModule({
  pluginId: 'scaffolder',
  moduleId: 'github-org',
  register(env) {
    env.registerInit({
      deps: {
        scaffolder: scaffolderActionsExtensionPoint,
        config: coreServices.rootConfig,
      },
      async init({ scaffolder, config }) {
        const integrations = ScmIntegrations.fromConfig(config);
        const api: OrgApi = {
          integrations,
          credentials:
            DefaultGithubCredentialsProvider.fromIntegrations(integrations),
        };
        scaffolder.addActions(
          createTeamAction(api),
          addTeamMemberAction(api),
          createInvitationAction(api),
        );
      },
    });
  },
});
