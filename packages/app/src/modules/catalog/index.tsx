import {
  RELATION_API_CONSUMED_BY,
  RELATION_API_PROVIDED_BY,
  RELATION_CONSUMES_API,
  RELATION_DEPENDENCY_OF,
  RELATION_DEPENDS_ON,
  RELATION_HAS_PART,
  RELATION_PART_OF,
  RELATION_PROVIDES_API,
} from '@backstage/catalog-model';
import { compatWrapper } from '@backstage/core-compat-api';
import {
  coreExtensionData,
  createFrontendModule,
} from '@backstage/frontend-plugin-api';
import {
  EntityDependsOnComponentsCard,
  EntityDependsOnResourcesCard,
} from '@backstage/plugin-catalog';
import catalogPlugin, {
  CatalogIndexPage,
} from '@backstage/plugin-catalog/alpha';
import {
  Direction,
  EntityCatalogGraphCard,
} from '@backstage/plugin-catalog-graph';
import {
  EntityCardBlueprint,
  EntityContentBlueprint,
} from '@backstage/plugin-catalog-react/alpha';
import { Grid } from '@material-ui/core';
import { GitHubOrgActionsCard } from '../../components/github';
import { customCatalogColumns } from './catalogColumns';

/** Catalog index page rendered with the custom per-kind table columns. */
const catalogIndexPage = catalogPlugin.getExtension('page:catalog').override({
  factory(originalFactory, { inputs, config }) {
    return originalFactory({
      params: {
        loader: async () => (
          <CatalogIndexPage
            columns={customCatalogColumns}
            filters={
              <>
                {inputs.filters.map(filter =>
                  filter.get(coreExtensionData.reactElement),
                )}
              </>
            }
            pagination={config.pagination}
            exportSettings={
              config.exportSettings?.enabled ? config.exportSettings : undefined
            }
          />
        ),
      },
    });
  },
});

const githubOrgActionsCard = EntityCardBlueprint.make({
  name: 'github-org-actions',
  params: {
    filter: { kind: { $in: ['user', 'group'] } },
    loader: async () => <GitHubOrgActionsCard />,
  },
});

const dependenciesContent = EntityContentBlueprint.make({
  name: 'dependencies',
  params: {
    path: '/dependencies',
    title: 'Dependencies',
    group: 'development',
    filter: {
      kind: 'component',
      'spec.type': { $in: ['service', 'website'] },
    },
    loader: async () =>
      compatWrapper(
        <Grid container spacing={3} alignItems="stretch">
          <Grid item md={6}>
            <EntityDependsOnComponentsCard variant="gridItem" />
          </Grid>
          <Grid item md={6}>
            <EntityDependsOnResourcesCard variant="gridItem" />
          </Grid>
        </Grid>,
      ),
  },
});

const systemDiagramContent = EntityContentBlueprint.make({
  name: 'system-diagram',
  params: {
    path: '/diagram',
    title: 'Diagram',
    filter: { kind: 'system' },
    loader: async () =>
      compatWrapper(
        <EntityCatalogGraphCard
          direction={Direction.TOP_BOTTOM}
          title="System Diagram"
          height={700}
          relations={[
            RELATION_PART_OF,
            RELATION_HAS_PART,
            RELATION_API_CONSUMED_BY,
            RELATION_API_PROVIDED_BY,
            RELATION_CONSUMES_API,
            RELATION_PROVIDES_API,
            RELATION_DEPENDENCY_OF,
            RELATION_DEPENDS_ON,
          ]}
          unidirectional={false}
        />,
      ),
  },
});

export const catalogModule = createFrontendModule({
  pluginId: 'catalog',
  extensions: [
    catalogIndexPage,
    githubOrgActionsCard,
    dependenciesContent,
    systemDiagramContent,
  ],
});
