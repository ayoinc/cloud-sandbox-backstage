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
  const [primaryColor, setPrimaryColor] = useState(settings.primaryColor || '');
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const logoFullInputRef = useRef<HTMLInputElement>(null);
  const logoIconInputRef = useRef<HTMLInputElement>(null);

  // Sync local state when settings change
  useEffect(() => {
    setOrganizationName(settings.organizationName || '');
    setPrimaryColor(settings.primaryColor || '');
  }, [settings]);

  if (!isAdmin) {
    return (
      <Card className={classes.root}>
        <CardContent>
          <Alert severity="warning">
            You need to be a member of the <strong>admins</strong> group to
            access branding settings.
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
        primaryColor: primaryColor || null,
      });
      setSuccessMessage('Settings saved successfully');
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
    // eslint-disable-next-line no-alert
    if (
      !window.confirm('Are you sure you want to reset the logo to default?')
    ) {
      return;
    }
    try {
      setSaving(true);
      await resetLogo();
      setSuccessMessage('Logo reset to default');
    } catch {
      // Error is handled in context
    } finally {
      setSaving(false);
    }
  };

  const handleResetAll = async () => {
    // eslint-disable-next-line no-alert
    if (
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
        title="Branding Settings"
        subheader="Customize the look and feel of your Backstage instance"
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
            helperText="This name will appear in the sidebar and page titles"
            variant="outlined"
            disabled={saving}
          />
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
                      Default Logo
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

        <Divider style={{ margin: '24px 0' }} />

        {/* Primary Color Section (future) */}
        <div className={classes.section}>
          <Typography variant="h6" className={classes.sectionTitle}>
            Theme Color (Coming Soon)
          </Typography>
          <TextField
            fullWidth
            label="Primary Color"
            value={primaryColor}
            onChange={e => setPrimaryColor(e.target.value)}
            placeholder="#7df3e1"
            helperText="Hex color code for primary brand color (feature coming soon)"
            variant="outlined"
            disabled
          />
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
        {settings.updatedBy && (
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
