/*
 * Points the entities of the portal's own repository at its pipeline.
 *
 * The CI/CD tab of an entity lists the GitHub Actions runs of the repository
 * named by its `github.com/project-slug` annotation. The components and
 * templates kept in this repository are built, tested and checked by this
 * repository's workflows, so that is the repository they should name. Writing
 * it into every entity file would break in a fork; instead the pipeline
 * scripts pass the repository they run in as `pipeline.repository` (see
 * writeRunConfig in edge/scripts/pipeline/backend.mjs) and this module adds
 * the annotation while the catalog processes the files.
 *
 * Only entities read from that repository are touched, and only when they do
 * not name a repository themselves. Without `pipeline.repository`, as when
 * the catalog is read from a checkout, nothing is added.
 */

import {
  coreServices,
  createBackendModule,
} from '@backstage/backend-plugin-api';
import { Entity } from '@backstage/catalog-model';
import {
  CatalogProcessor,
  LocationSpec,
  catalogProcessingExtensionPoint,
} from '@backstage/plugin-catalog-node';

const PROJECT_SLUG_ANNOTATION = 'github.com/project-slug';

// The kinds this repository's workflows build or check. The other kinds
// (systems, domains, APIs, resources, users, groups) describe an organisation
// and have no pipeline.
const KINDS_WITH_PIPELINE: Record<string, true> = {
  component: true,
  template: true,
};

export class OwnRepositoryProcessor implements CatalogProcessor {
  private readonly slug: string;
  private readonly urlPrefix: string;

  /**
   * @param slug - `<owner>/<repo>` of the portal's repository
   * @param url - its address, e.g. `https://github.com/<owner>/<repo>`
   */
  constructor(slug: string, url: string) {
    this.slug = slug;
    // GitHub addresses are not case sensitive. The slash keeps a repository
    // whose name merely starts with this one out.
    this.urlPrefix = `${url.replace(/\/+$/, '')}/`.toLowerCase();
  }

  getProcessorName(): string {
    return 'OwnRepositoryProcessor';
  }

  async preProcessEntity(
    entity: Entity,
    location: LocationSpec,
  ): Promise<Entity> {
    if (
      KINDS_WITH_PIPELINE[entity.kind.toLowerCase()] !== true ||
      location.type !== 'url' ||
      !location.target.toLowerCase().startsWith(this.urlPrefix) ||
      entity.metadata.annotations?.[PROJECT_SLUG_ANNOTATION]
    ) {
      return entity;
    }
    return {
      ...entity,
      metadata: {
        ...entity.metadata,
        annotations: {
          ...entity.metadata.annotations,
          [PROJECT_SLUG_ANNOTATION]: this.slug,
        },
      },
    };
  }
}

export default createBackendModule({
  pluginId: 'catalog',
  moduleId: 'own-repository',
  register(env) {
    env.registerInit({
      deps: {
        catalog: catalogProcessingExtensionPoint,
        config: coreServices.rootConfig,
      },
      async init({ catalog, config }) {
        const repository = config.getOptionalConfig('pipeline.repository');
        if (repository) {
          catalog.addProcessor(
            new OwnRepositoryProcessor(
              repository.getString('slug'),
              repository.getString('url'),
            ),
          );
        }
      },
    });
  },
});
