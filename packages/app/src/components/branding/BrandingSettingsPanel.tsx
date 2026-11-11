import { useState, useRef, useEffect } from 'react';
import {
  Card,
  CardContent,
  CardHeader,
  Typography,
  TextField,
  Button,
  Box,
  Grid,
  Divider,
  CircularProgress,
  IconButton,
  Tooltip,
} from '@material-ui/core';
import { Alert } from '@material-ui/lab';
import { makeStyles } from '@material-ui/core/styles';
import CloudUploadIcon from '@material-ui/icons/CloudUpload';
import DeleteIcon from '@material-ui/icons/Delete';
import RefreshIcon from '@material-ui/icons/Refresh';
import SaveIcon from '@material-ui/icons/Save';
import { brandTokensFor, presetIds, presets } from '@internal/brand';
import type { PresetId } from '@internal/brand';
import { useBranding } from './BrandingContext';

const useStyles = makeStyles(theme => ({
  root: {
    marginBottom: theme.spacing(3),
  },
  section: {
    marginBottom: theme.spacing(3),
  },
  sectionTitle: {
    marginBottom: theme.spacing(2),
    fontWeight: 600,
  },
  logoPreview: {
    maxWidth: 200,
    maxHeight: 60,
    objectFit: 'contain',
    border: `1px solid ${theme.palette.divider}`,
    borderRadius: theme.shape.borderRadius,
    padding: theme.spacing(1),
    backgroundColor: theme.palette.background.default,
  },
  logoIconPreview: {
    maxWidth: 60,
    maxHeight: 60,
    objectFit: 'contain',
    border: `1px solid ${theme.palette.divider}`,
    borderRadius: theme.shape.borderRadius,
    padding: theme.spacing(1),
    backgroundColor: theme.palette.background.default,
  },
  uploadButton: {
    marginTop: theme.spacing(1),
  },
  fileInput: {
    display: 'none',
  },
  previewContainer: {
    display: 'flex',
    alignItems: 'center',
    gap: theme.spacing(2),
    marginBottom: theme.spacing(2),
  },
  actions: {
    display: 'flex',
    gap: theme.spacing(1),
    marginTop: theme.spacing(2),
  },
  presets: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))',
    gap: theme.spacing(1.5),
    marginBottom: theme.spacing(3),
  },
  preset: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'stretch',
    gap: theme.spacing(1),
    minHeight: 44,
    padding: theme.spacing(1.5),
    textAlign: 'left',
    font: 'inherit',
    color: theme.palette.text.primary,
    background: theme.palette.background.paper,
    border: `1px solid ${theme.palette.divider}`,
    borderRadius: theme.shape.borderRadius,
    cursor: 'pointer',
    transition: 'border-color 150ms, box-shadow 150ms',
    '&:hover': { borderColor: theme.palette.text.secondary },
    '&[aria-checked="true"]': {
      borderColor: theme.palette.primary.main,
      boxShadow: `inset 0 0 0 1px ${theme.palette.primary.main}`,
    },
    '&:disabled': { cursor: 'default', opacity: 0.6 },
  },
  swatches: {
    display: 'flex',
    height: 28,
    overflow: 'hidden',
    border: `1px solid ${theme.palette.divider}`,
    '& > span': { flex: 1 },
  },
  presetText: { color: theme.palette.text.secondary, fontSize: '0.8125rem' },
  colorRow: {
    display: 'flex',
    alignItems: 'center',
    gap: theme.spacing(1.5),
    flexWrap: 'wrap',
  },
  colorInput: {
    width: 44,
    height: 44,
    padding: 0,
    border: `1px solid ${theme.palette.divider}`,
    borderRadius: theme.shape.borderRadius,
    background: 'none',
    cursor: 'pointer',
  },
  dangerZone: {
    marginTop: theme.spacing(4),
    padding: theme.spacing(2),
    border: `1px solid ${theme.palette.error.main}`,
    borderRadius: theme.shape.borderRadius,
  },
  dangerTitle: {
    color: theme.palette.error.main,
    marginBottom: theme.spacing(2),
  },
  metadata: {
    marginTop: theme.spacing(2),
    color: theme.palette.text.secondary,
    fontSize: '0.875rem',
  },
}));

export const BrandingSettingsPanel: React.FC = () => {
  const classes = useStyles();
  const {
    settings,
    isLoading,
    isAdmin,
    error,
    refresh,
    updateSettings,
    uploadLogo,
    resetLogo,
    resetAll,
  } = useBranding();

  const [organizationName, setOrganizationName] = useState(
    settings.organizationName || '',
  );
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const activePreset = brandTokensFor(settings.themePreset).preset;
  const [primaryColor, setPrimaryColor] = useState(settings.primaryColor);

  const logoFullInputRef = useRef<HTMLInputElement>(null);
  const logoIconInputRef = useRef<HTMLInputElement>(null);

  // Sync local state when settings change
  useEffect(() => {
    setOrganizationName(settings.organizationName || '');
    setPrimaryColor(settings.primaryColor);
  }, [settings]);

  if (!isAdmin) {
    return (
      <Card className={classes.root}>
        <CardContent>
          <Alert severity="warning">
            Only a portal administrator can change the branding. Ask one to add
            you under Branding administrators.
          </Alert>
        </CardContent>
      </Card>
    );
  }

  const handleSaveSettings = async () => {
    try {
      setSaving(true);
      setSuccessMessage(null);
      await updateSettings({
        organizationName: organizationName || null,
      });
      setSuccessMessage('Settings saved successfully');
    } catch {
      // Error is handled in context
    } finally {
      setSaving(false);
    }
  };

  const handleTheme = async (
    updates: { themePreset: PresetId } | { primaryColor: string | null },
    message: string,
  ) => {
    try {
      setSaving(true);
      setSuccessMessage(null);
      await updateSettings(updates);
      setSuccessMessage(message);
    } catch {
      // Error is handled in context
    } finally {
      setSaving(false);
    }
  };

  const handleLogoUpload = async (type: 'full' | 'icon', file: File) => {
    try {
      setUploading(true);
      setSuccessMessage(null);
      if (type === 'full') {
        await uploadLogo(file, undefined);
      } else {
        await uploadLogo(undefined, file);
      }
      setSuccessMessage(
        `Logo ${type === 'full' ? '(full)' : '(icon)'} uploaded successfully`,
      );
    } catch {
      // Error is handled in context
    } finally {
      setUploading(false);
    }
  };

  const handleResetLogo = async () => {
    if (
      // eslint-disable-next-line no-alert
      !window.confirm('Remove the uploaded logo?')
    ) {
      return;
    }
    try {
      setSaving(true);
      await resetLogo();
      setSuccessMessage('Logo removed');
    } catch {
      // Error is handled in context
    } finally {
      setSaving(false);
    }
  };

  const handleResetAll = async () => {
    if (
      // eslint-disable-next-line no-alert
      !window.confirm(
        'Are you sure you want to reset ALL branding settings to default? This cannot be undone.',
      )
    ) {
      return;
    }
    try {
      setSaving(true);
      await resetAll();
      setSuccessMessage('All branding settings reset to default');
    } catch {
      // Error is handled in context
    } finally {
      setSaving(false);
    }
  };

  if (isLoading) {
    return (
      <Card className={classes.root}>
        <CardContent>
          <Box display="flex" justifyContent="center" p={3}>
            <CircularProgress />
          </Box>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className={classes.root}>
      <CardHeader
        title="Branding settings"
        subheader="The portal has no name, logo or colours of its own until you set them here"
        action={
          <Tooltip title="Refresh">
            <IconButton onClick={refresh} disabled={saving || uploading}>
              <RefreshIcon />
            </IconButton>
          </Tooltip>
        }
      />
      <CardContent>
        {error && (
          <Alert severity="error" style={{ marginBottom: 16 }}>
            {error}
          </Alert>
        )}
        {successMessage && (
          <Alert severity="success" style={{ marginBottom: 16 }}>
            {successMessage}
          </Alert>
        )}

        {/* Organization Name Section */}
        <div className={classes.section}>
          <Typography variant="h6" className={classes.sectionTitle}>
            Organization
          </Typography>
          <TextField
            fullWidth
            label="Organization / Team Name"
            value={organizationName}
            onChange={e => setOrganizationName(e.target.value)}
            placeholder="e.g., Platform Team, Acme Corp"
            helperText="Shown on the sign-in page and beside the logo"
            variant="outlined"
            disabled={saving}
          />
        </div>

        <Divider style={{ margin: '24px 0' }} />

        {/* Theme Section */}
        <div className={classes.section}>
          <Typography variant="h6" className={classes.sectionTitle}>
            Theme
          </Typography>
          <div
            className={classes.presets}
            role="radiogroup"
            aria-label="Theme preset"
          >
            {presetIds.map(id => {
              const { light } = brandTokensFor(id).color;
              return (
                <button
                  key={id}
                  type="button"
                  role="radio"
                  aria-checked={id === activePreset}
                  className={classes.preset}
                  style={{ borderRadius: brandTokensFor(id).shape.card }}
                  disabled={saving}
                  onClick={() =>
                    handleTheme(
                      { themePreset: id },
                      `Theme changed to ${presets[id].title}`,
                    )
                  }
                >
                  <span className={classes.swatches} aria-hidden="true">
                    <span style={{ background: light.navigation.background }} />
                    <span style={{ background: light.primary }} />
                    <span style={{ background: light.primaryContainer }} />
                    <span style={{ background: light.surfaceContainerLow }} />
                  </span>
                  <strong>{presets[id].title}</strong>
                  <span className={classes.presetText}>
                    {presets[id].description}
                  </span>
                </button>
              );
            })}
          </div>
          <Typography variant="subtitle2" gutterBottom>
            Primary colour
          </Typography>
          <div className={classes.colorRow}>
            <input
              type="color"
              aria-label="Primary colour"
              className={classes.colorInput}
              value={
                primaryColor ?? brandTokensFor(activePreset).color.light.primary
              }
              onChange={e => setPrimaryColor(e.target.value)}
              disabled={saving}
            />
            <Button
              variant="outlined"
              disabled={
                saving ||
                !primaryColor ||
                primaryColor === settings.primaryColor
              }
              onClick={() =>
                handleTheme({ primaryColor }, 'Primary colour saved')
              }
            >
              Use this colour
            </Button>
            <Button
              disabled={saving || !settings.primaryColor}
              onClick={() =>
                handleTheme(
                  { primaryColor: null },
                  "Primary colour back to the preset's",
                )
              }
            >
              Use the preset's colour
            </Button>
          </div>
          <Typography className={classes.metadata}>
            Buttons and links take this colour. Text on it stays readable: where
            the colour is too pale for links, links keep the preset's.
          </Typography>
        </div>

        <Divider style={{ margin: '24px 0' }} />

        {/* Logo Section */}
        <div className={classes.section}>
          <Typography variant="h6" className={classes.sectionTitle}>
            Logo
          </Typography>

          <Grid container spacing={4}>
            {/* Full Logo */}
            <Grid item xs={12} md={6}>
              <Typography variant="subtitle2" gutterBottom>
                Full Logo (expanded sidebar)
              </Typography>
              <div className={classes.previewContainer}>
                {settings.logoFullUrl ? (
                  <img
                    src={settings.logoFullUrl}
                    alt="Full Logo"
                    className={classes.logoPreview}
                  />
                ) : (
                  <Box
                    className={classes.logoPreview}
                    display="flex"
                    alignItems="center"
                    justifyContent="center"
                  >
                    <Typography variant="caption" color="textSecondary">
                      No logo yet
                    </Typography>
                  </Box>
                )}
              </div>
              <input
                type="file"
                ref={logoFullInputRef}
                className={classes.fileInput}
                accept="image/png,image/jpeg,image/svg+xml,image/webp,image/gif"
                onChange={e => {
                  const file = e.target.files?.[0];
                  if (file) handleLogoUpload('full', file);
                }}
              />
              <Button
                variant="outlined"
                startIcon={<CloudUploadIcon />}
                onClick={() => logoFullInputRef.current?.click()}
                disabled={uploading || saving}
                className={classes.uploadButton}
              >
                Upload Full Logo
              </Button>
              <Typography
                variant="caption"
                display="block"
                color="textSecondary"
                style={{ marginTop: 8 }}
              >
                Recommended: SVG or PNG, height ~30px
              </Typography>
            </Grid>

            {/* Icon Logo */}
            <Grid item xs={12} md={6}>
              <Typography variant="subtitle2" gutterBottom>
                Icon Logo (collapsed sidebar)
              </Typography>
              <div className={classes.previewContainer}>
                {settings.logoIconUrl ? (
                  <img
                    src={settings.logoIconUrl}
                    alt="Icon Logo"
                    className={classes.logoIconPreview}
                  />
                ) : (
                  <Box
                    className={classes.logoIconPreview}
                    display="flex"
                    alignItems="center"
                    justifyContent="center"
                  >
                    <Typography variant="caption" color="textSecondary">
                      Default
                    </Typography>
                  </Box>
                )}
              </div>
              <input
                type="file"
                ref={logoIconInputRef}
                className={classes.fileInput}
                accept="image/png,image/jpeg,image/svg+xml,image/webp,image/gif"
                onChange={e => {
                  const file = e.target.files?.[0];
                  if (file) handleLogoUpload('icon', file);
                }}
              />
              <Button
                variant="outlined"
                startIcon={<CloudUploadIcon />}
                onClick={() => logoIconInputRef.current?.click()}
                disabled={uploading || saving}
                className={classes.uploadButton}
              >
                Upload Icon Logo
              </Button>
              <Typography
                variant="caption"
                display="block"
                color="textSecondary"
                style={{ marginTop: 8 }}
              >
                Recommended: Square SVG or PNG, ~28x28px
              </Typography>
            </Grid>
          </Grid>

          {(settings.logoFullUrl || settings.logoIconUrl) && (
            <Box mt={2}>
              <Button
                variant="outlined"
                color="secondary"
                startIcon={<DeleteIcon />}
                onClick={handleResetLogo}
                disabled={uploading || saving}
              >
                Reset Logo to Default
              </Button>
            </Box>
          )}
        </div>

        {/* Save Button */}
        <Box className={classes.actions}>
          <Button
            variant="contained"
            color="primary"
            startIcon={saving ? <CircularProgress size={20} /> : <SaveIcon />}
            onClick={handleSaveSettings}
            disabled={saving || uploading}
          >
            {saving ? 'Saving...' : 'Save Settings'}
          </Button>
        </Box>

        {/* Metadata */}
        {settings.updatedBy && settings.updatedAt && (
          <Typography className={classes.metadata}>
            Last updated by {settings.updatedBy} on{' '}
            {new Date(settings.updatedAt).toLocaleString()}
          </Typography>
        )}

        {/* Danger Zone */}
        <div className={classes.dangerZone}>
          <Typography variant="h6" className={classes.dangerTitle}>
            Danger Zone
          </Typography>
          <Typography variant="body2" paragraph>
            Reset all branding settings to their default values. This will
            remove custom logos and organization name.
          </Typography>
          <Button
            variant="outlined"
            color="secondary"
            startIcon={<DeleteIcon />}
            onClick={handleResetAll}
            disabled={saving || uploading}
          >
            Reset All Branding
          </Button>
        </div>
      </CardContent>
    </Card>
  );
};

export default BrandingSettingsPanel;
