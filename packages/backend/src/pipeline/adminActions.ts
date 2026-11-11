/*
 * Template actions that change the operator's GitHub organisation with the
 * portal's own token: its teams, their members and who is invited. A
 * template that uses one may be run by portal administrators only.
 *
 * The Node backend's permission policy and the Worker both read this list,
 * so it imports nothing. Every action registered in ./githubOrgActions.ts
 * must be on it.
 */
export const ADMIN_ONLY_ACTIONS: readonly string[] = [
  'github:team:create',
  'github:team:member:add',
  'github:org:invitation:create',
];
