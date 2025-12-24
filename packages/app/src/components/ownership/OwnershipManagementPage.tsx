import { useState, useEffect, useCallback } from 'react';
import {
  Content,
  Header,
  Page,
  Table,
  TableColumn,
  Progress,
  WarningPanel,
  InfoCard,
} from '@backstage/core-components';
import { useApi, fetchApiRef, alertApiRef } from '@backstage/core-plugin-api';
import {
  Button,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  FormControl,
  Grid,
  InputLabel,
  MenuItem,
  Select as MuiSelect,
  Tab,
  Tabs,
  Typography,
  makeStyles,
} from '@material-ui/core';
import WarningIcon from '@material-ui/icons/Warning';
import CheckCircleIcon from '@material-ui/icons/CheckCircle';

const useStyles = makeStyles(theme => ({
  orphanChip: {
    backgroundColor: theme.palette.warning.main,
    color: theme.palette.warning.contrastText,
  },
  validChip: {
    backgroundColor: theme.palette.success.main,
    color: theme.palette.success.contrastText,
  },
  tabPanel: {
    paddingTop: theme.spacing(2),
  },
  statsCard: {
    marginBottom: theme.spacing(2),
  },
  formControl: {
    minWidth: 200,
  },
}));

interface EntityInfo {
  entityRef: string;
  kind: string;
  name: string;
  namespace: string;
  currentOwner: string;
  title?: string;
  ownerExists?: boolean;
}

interface GroupInfo {
  name: string;
  displayName: string;
  description?: string;
  entityRef: string;
}

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;
  return (
    <div role="tabpanel" hidden={value !== index} {...other}>
      {value === index && <div>{children}</div>}
    </div>
  );
}

export const OwnershipManagementPage = () => {
  const classes = useStyles();
  const fetchApi = useApi(fetchApiRef);
  const alertApi = useApi(alertApiRef);

  const [tabValue, setTabValue] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [entities, setEntities] = useState<EntityInfo[]>([]);
  const [orphans, setOrphans] = useState<EntityInfo[]>([]);
  const [groups, setGroups] = useState<GroupInfo[]>([]);
  const [selectedEntity, setSelectedEntity] = useState<EntityInfo | null>(null);
  const [selectedNewOwner, setSelectedNewOwner] = useState('');
  const [dialogOpen, setDialogOpen] = useState(false);
  const [reassigning, setReassigning] = useState(false);

  const loadData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [entitiesRes, orphansRes, groupsRes] = await Promise.all([
        fetchApi.fetch('/api/ownership-management/entities'),
        fetchApi.fetch('/api/ownership-management/orphans'),
        fetchApi.fetch('/api/ownership-management/groups'),
      ]);

      const errors: string[] = [];

      if (entitiesRes.ok) {
        const data = await entitiesRes.json();
        setEntities(data.entities || []);
      } else {
        errors.push(`Entities: ${entitiesRes.statusText}`);
        setEntities([]);
      }
      if (orphansRes.ok) {
        const data = await orphansRes.json();
        setOrphans(data.orphans || []);
      } else {
        errors.push(`Orphans: ${orphansRes.statusText}`);
        setOrphans([]);
      }
      if (groupsRes.ok) {
        const data = await groupsRes.json();
        setGroups(data.groups || []);
      } else {
        errors.push(`Groups: ${groupsRes.statusText}`);
        setGroups([]);
      }

      if (errors.length > 0) {
        setError(`Failed to load some data: ${errors.join(', ')}`);
      }
    } catch (e) {
      const message = e instanceof Error ? e.message : 'Unknown error';
      setError(`Failed to load ownership data: ${message}`);
      alertApi.post({
        message: 'Failed to load ownership data',
        severity: 'error',
      });
    } finally {
      setLoading(false);
    }
  }, [fetchApi, alertApi]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const handleReassign = (entity: EntityInfo) => {
    setSelectedEntity(entity);
    setSelectedNewOwner('');
    setDialogOpen(true);
  };

  const handleConfirmReassign = async () => {
    if (!selectedEntity || !selectedNewOwner) return;

    setReassigning(true);
    try {
      const response = await fetchApi.fetch(
        '/api/ownership-management/reassign',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            entityRef: selectedEntity.entityRef,
            newOwner: selectedNewOwner,
          }),
        },
      );

      const data = await response.json();

      if (response.ok) {
        alertApi.post({
          message: data.message || 'Ownership reassignment recorded',
          severity: 'success',
        });
        setDialogOpen(false);
        loadData();
      } else {
        alertApi.post({
          message: data.error || 'Failed to reassign ownership',
          severity: 'error',
        });
      }
    } catch {
      alertApi.post({
        message: 'Failed to reassign ownership',
        severity: 'error',
      });
    } finally {
      setReassigning(false);
    }
  };

  const columns: TableColumn<EntityInfo>[] = [
    {
      title: 'Kind',
      field: 'kind',
      width: '100px',
    },
    {
      title: 'Name',
      field: 'name',
      render: (row: EntityInfo) => row.title || row.name,
    },
    {
      title: 'Namespace',
      field: 'namespace',
      width: '120px',
    },
    {
      title: 'Current Owner',
      field: 'currentOwner',
      render: (row: EntityInfo) => (
        <Chip
          size="small"
          label={row.currentOwner}
          icon={row.ownerExists ? <CheckCircleIcon /> : <WarningIcon />}
          className={row.ownerExists ? classes.validChip : classes.orphanChip}
        />
      ),
    },
    {
      title: 'Actions',
      field: 'actions',
      width: '150px',
      render: (row: EntityInfo) => (
        <Button
          variant="outlined"
          size="small"
          color="primary"
          onClick={() => handleReassign(row)}
        >
          Reassign
        </Button>
      ),
    },
  ];

  const orphanColumns: TableColumn<EntityInfo>[] = [
    {
      title: 'Kind',
      field: 'kind',
      width: '100px',
    },
    {
      title: 'Name',
      field: 'name',
      render: (row: EntityInfo) => row.title || row.name,
    },
    {
      title: 'Missing Owner',
      field: 'currentOwner',
      render: (row: EntityInfo) => (
        <Chip
          size="small"
          label={row.currentOwner}
          icon={<WarningIcon />}
          className={classes.orphanChip}
        />
      ),
    },
    {
      title: 'Actions',
      field: 'actions',
      width: '150px',
      render: (row: EntityInfo) => (
        <Button
          variant="contained"
          size="small"
          color="primary"
          onClick={() => handleReassign(row)}
        >
          Assign Owner
        </Button>
      ),
    },
  ];

  if (loading) {
    return (
      <Page themeId="tool">
        <Header
          title="Ownership Management"
          subtitle="Manage entity ownership and orphans"
        />
        <Content>
          <Progress />
        </Content>
      </Page>
    );
  }

  return (
    <Page themeId="tool">
      <Header
        title="Ownership Management"
        subtitle="Manage entity ownership and orphans"
      />
      <Content>
        <Grid container spacing={3}>
          {/* Error Panel */}
          {error && (
            <Grid item xs={12}>
              <WarningPanel severity="error" title="Error loading data">
                {error}
              </WarningPanel>
            </Grid>
          )}

          {/* Stats Cards */}
          <Grid item xs={12} md={4}>
            <InfoCard title="Total Entities" className={classes.statsCard}>
              <Typography variant="h3">{entities.length}</Typography>
              <Typography variant="body2" color="textSecondary">
                Components, APIs, Resources, Systems, Domains
              </Typography>
            </InfoCard>
          </Grid>
          <Grid item xs={12} md={4}>
            <InfoCard title="Orphaned Entities" className={classes.statsCard}>
              <Typography
                variant="h3"
                color={orphans.length > 0 ? 'error' : 'inherit'}
              >
                {orphans.length}
              </Typography>
              <Typography variant="body2" color="textSecondary">
                Entities with missing owners
              </Typography>
            </InfoCard>
          </Grid>
          <Grid item xs={12} md={4}>
            <InfoCard title="Available Groups" className={classes.statsCard}>
              <Typography variant="h3">{groups.length}</Typography>
              <Typography variant="body2" color="textSecondary">
                Groups available for assignment
              </Typography>
            </InfoCard>
          </Grid>

          {/* Warning for orphans */}
          {orphans.length > 0 && (
            <Grid item xs={12}>
              <WarningPanel
                severity="warning"
                title={`${orphans.length} orphaned entities found`}
              >
                These entities have owners that no longer exist. Please reassign
                them to active groups.
              </WarningPanel>
            </Grid>
          )}

          {/* Tabs */}
          <Grid item xs={12}>
            <Tabs
              value={tabValue}
              onChange={(_, newValue) => setTabValue(newValue)}
              indicatorColor="primary"
              textColor="primary"
            >
              <Tab label={`Orphaned (${orphans.length})`} />
              <Tab label={`All Entities (${entities.length})`} />
            </Tabs>

            <div className={classes.tabPanel}>
              <TabPanel value={tabValue} index={0}>
                {orphans.length === 0 ? (
                  <InfoCard title="No Orphans">
                    <Typography>All entities have valid owners.</Typography>
                  </InfoCard>
                ) : (
                  <Table
                    title="Orphaned Entities"
                    options={{
                      search: true,
                      paging: true,
                      pageSize: 10,
                      pageSizeOptions: [10, 25, 50],
                    }}
                    columns={orphanColumns}
                    data={orphans}
                  />
                )}
              </TabPanel>

              <TabPanel value={tabValue} index={1}>
                <Table
                  title="All Ownable Entities"
                  options={{
                    search: true,
                    paging: true,
                    pageSize: 10,
                    pageSizeOptions: [10, 25, 50],
                  }}
                  columns={columns}
                  data={entities}
                />
              </TabPanel>
            </div>
          </Grid>
        </Grid>

        {/* Reassign Dialog */}
        <Dialog
          open={dialogOpen}
          onClose={() => setDialogOpen(false)}
          maxWidth="sm"
          fullWidth
        >
          <DialogTitle>Reassign Ownership</DialogTitle>
          <DialogContent>
            <DialogContentText>
              Select a new owner for{' '}
              <strong>{selectedEntity?.title || selectedEntity?.name}</strong>
            </DialogContentText>
            <FormControl
              fullWidth
              className={classes.formControl}
              style={{ marginTop: 16 }}
            >
              <InputLabel id="new-owner-label">New Owner</InputLabel>
              <MuiSelect
                labelId="new-owner-label"
                value={selectedNewOwner}
                onChange={e => setSelectedNewOwner(e.target.value as string)}
              >
                {groups.map(group => (
                  <MenuItem key={group.entityRef} value={group.name}>
                    {group.displayName} ({group.name})
                  </MenuItem>
                ))}
              </MuiSelect>
            </FormControl>
            {selectedEntity && (
              <Typography
                variant="body2"
                color="textSecondary"
                style={{ marginTop: 16 }}
              >
                Current owner: {selectedEntity.currentOwner}
              </Typography>
            )}
            <Typography
              variant="body2"
              color="textSecondary"
              style={{ marginTop: 8 }}
            >
              Note: For file-based entities, you will also need to update the
              catalog-info.yaml in the source repository.
            </Typography>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setDialogOpen(false)} color="default">
              Cancel
            </Button>
            <Button
              onClick={handleConfirmReassign}
              color="primary"
              variant="contained"
              disabled={!selectedNewOwner || reassigning}
            >
              {reassigning ? 'Reassigning...' : 'Reassign'}
            </Button>
          </DialogActions>
        </Dialog>
      </Content>
    </Page>
  );
};

export default OwnershipManagementPage;
