export interface Config {
  organization?: {
    /**
     * The GitHub organisation this portal manages, as it appears in
     * github.com/orgs/<name>. Pages that link to the organisation show those
     * links once this is set.
     * @visibility frontend
     */
    githubOrg?: string;
  };
}
