/**
 * What the backend's plugins need to know from each other to keep one
 * account's things from another: who is in which organisation, who
 * administers the portal, and which registered catalog file is whose.
 *
 * Each plugin has its own database, so none can look this up itself. The
 * plugin that holds an answer provides it here when it starts, and the
 * others ask here. Asking before the answer is provided throws, so a request
 * that arrives during start-up is refused instead of being let through.
 *
 * An account is an organisation, written `organisation:<id>` with the id
 * that never changes, or, for someone who is in none, the person:
 * `user:default/jane`, in lower case.
 */

/** The annotation that names the account an entity belongs to. */
export const ACCOUNT_ANNOTATION = 'portal/account';

/** The account of a registered file nobody has taken: shown to no one. */
export const UNCLAIMED_ACCOUNT = 'unclaimed';

export const organisationAccount = (id: string) => `organisation:${id}`;

export interface Memberships {
  /**
   * The accounts whose things `userRef` sees: their own, and their
   * organisation's when they are in one.
   */
  accountsOf(userRef: string): Promise<string[]>;
  /**
   * The account that what `userRef` registers is filed under: their
   * organisation when they are in one, otherwise their own.
   */
  accountFor(userRef: string): Promise<string>;
}

export interface PortalAdmins {
  /** Whether the user, or a group their token names, administers the portal. */
  isPortalAdmin(userRef: string, ownershipRefs: string[]): Promise<boolean>;
  /** Every portal administrator: user and group refs, in lower case. */
  portalAdmins(): Promise<string[]>;
}

export interface LocationAccounts {
  /** Files everything registered under account `from` under `to`. */
  moveAccount(from: string, to: string): Promise<void>;
}

interface Directory extends Memberships, PortalAdmins, LocationAccounts {}

const provided: Partial<Directory> = {};

/** Called once by the plugin that holds these answers, when it starts. */
export function provide(
  answers: Memberships | PortalAdmins | LocationAccounts,
): void {
  Object.assign(provided, answers);
}

const ask =
  <K extends keyof Directory>(name: K) =>
  (...args: Parameters<Directory[K]>): ReturnType<Directory[K]> => {
    const answer = provided[name] as
      | ((...a: Parameters<Directory[K]>) => ReturnType<Directory[K]>)
      | undefined;
    if (!answer) {
      throw new Error(`The portal is still starting: ${name} is not ready`);
    }
    return answer(...args);
  };

export const directory: Directory = {
  accountsOf: ask('accountsOf'),
  accountFor: ask('accountFor'),
  isPortalAdmin: ask('isPortalAdmin'),
  portalAdmins: ask('portalAdmins'),
  moveAccount: ask('moveAccount'),
};
