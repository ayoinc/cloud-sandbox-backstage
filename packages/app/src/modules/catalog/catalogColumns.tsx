import { TableColumn } from '@backstage/core-components';
import {
  CatalogTableColumnsFunc,
  CatalogTableRow,
  CatalogTable,
} from '@backstage/plugin-catalog';

/**
 * Custom columns function that shows username for User entities
 * For other entity types, uses default columns
 */
export const customCatalogColumns: CatalogTableColumnsFunc = context => {
  const { filters } = context;
  const kind = filters.kind?.value?.toLowerCase();

  // For User entities, show Display Name and Username
  if (kind === 'user') {
    const columns: TableColumn<CatalogTableRow>[] = [
      {
        title: 'Display Name',
        field: 'entity.spec.profile.displayName',
        highlight: true,
        render: (row: CatalogTableRow) => {
          const displayName = (row.entity?.spec as any)?.profile?.displayName;
          return displayName || row.entity?.metadata?.name || '';
        },
      },
      {
        title: 'Username',
        field: 'entity.metadata.name',
        render: (row: CatalogTableRow) => {
          return row.entity?.metadata?.name || '';
        },
      },
      {
        title: 'Email',
        field: 'entity.spec.profile.email',
        render: (row: CatalogTableRow) => {
          return (row.entity?.spec as any)?.profile?.email || '';
        },
      },
      {
        title: 'Description',
        field: 'entity.metadata.description',
      },
    ];
    return columns;
  }

  // For all other entity types, use the default columns
  return CatalogTable.defaultColumnsFunc(context);
};
