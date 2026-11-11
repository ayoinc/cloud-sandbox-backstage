import { useEffect, useRef, useState } from 'react';
import {
  Box,
  Button,
  Card,
  CardContent,
  CardHeader,
  Divider,
  Grid,
  TextField,
  Typography,
} from '@material-ui/core';
import { Alert } from '@material-ui/lab';
import { makeStyles } from '@material-ui/core/styles';
import CloudUploadIcon from '@material-ui/icons/CloudUpload';
import DeleteIcon from '@material-ui/icons/Delete';
import SaveIcon from '@material-ui/icons/Save';
import {
  brandTokensFor,
  logoSrc,
  organisationPath,
  presetIds,
  presets,
} from '@internal/brand';
import type { PresetId } from '@internal/brand';
import { ADDRESS, ADDRESS_RULE } from './CreateOrganisation';
import { useOrganisation } from './OrganisationContext';
import type { LogoKind } from './OrganisationContext';

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
  previewContainer: {
    display: 'flex',
    alignItems: 'center',
    gap: theme.spacing(2),
    marginBottom: theme.spacing(2),
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

/** The file types a logo may be, as the backend takes them. */
const LOGO_TYPES = 'image/png,image/jpeg,image/svg+xml,image/webp,image/gif';

const LOGOS = {
  full: {
    title: 'Full logo (open sidebar and sign-in page)',
    name: 'Full logo',
    hint: 'PNG, JPEG, SVG, WebP or GIF, up to 1 MB. Best about 30px high. Exported documents use PNG, JPEG or SVG only.',
  },
  icon: {
    title: 'Icon logo (collapsed sidebar)',
    name: 'Icon logo',
    hint: 'PNG, JPEG, SVG, WebP or GIF, up to 1 MB. Best square, about 28 by 28px.',
  },
};

/** One of the two logos: what is there now, and the buttons that change it. */
const LogoField = (props: {
  kind: LogoKind;
  url: string | null;
  disabled: boolean;
  onUpload: (file: File) => void;
  onRemove: () => void;
}) => {
  const classes = useStyles();
  const input = useRef<HTMLInputElement>(null);
  const { title, name, hint } = LOGOS[props.kind];
  return (
    <Grid item xs={12} md={6}>
      <Typography variant="subtitle2" gutterBottom>
        {title}
      </Typography>
      <div className={classes.previewContainer}>
        {props.url ? (
          <img
            src={logoSrc(props.url) ?? undefined}
            alt={name}
            className={classes.logoPreview}
          />
        ) : (
          <Typography variant="caption" color="textSecondary">
            No logo yet
          </Typography>
        )}
      </div>
      <input
        ref={input}
        type="file"
        accept={LOGO_TYPES}
        hidden
        onChange={event => {
          const file = event.target.files?.[0];
          if (file) {
            props.onUpload(file);
          }
          // So that choosing the same file again is still a change.
          event.target.value = '';
        }}
      />
      <Box display="flex" style={{ gap: 8 }}>
        <Button
          variant="outlined"
          startIcon={<CloudUploadIcon />}
          onClick={() => input.current?.click()}
          disabled={props.disabled}
        >
          Upload {name.toLowerCase()}
        </Button>
        {props.url && (
          <Button
            color="secondary"
            startIcon={<DeleteIcon />}
            onClick={props.onRemove}
            disabled={props.disabled}
          >
            Remove {name.toLowerCase()}
          </Button>
        )}
      </Box>
      <Typography
        variant="caption"
        color="textSecondary"
        display="block"
        style={{ marginTop: 8 }}
      >
        {hint}
      </Typography>
    </Grid>
  );
};

/**
 * The organisation's name, address, theme and logos. Shown to people who
 * have an organisation; only an owner can change anything.
 */
export const OrganisationSettingsPanel = () => {
  const classes = useStyles();
  const {
    organisation,
    role,
    error,
    update,
    rename,
    uploadLogo,
    removeLogo,
    remove,
  } = useOrganisation();
  // The page that shows this panel has checked that there is one.
  const settings = organisation!;

  const [name, setName] = useState(settings.name);
  const [address, setAddress] = useState(settings.slug);
  // What the backend said about the name or the address, shown beside it.
  const [refused, setRefused] = useState<{
    field: 'name' | 'slug';
    message: string;
  } | null>(null);
  const [saving, setSaving] = useState(false);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const activePreset = brandTokensFor(settings.themePreset).preset;
  const [primaryColor, setPrimaryColor] = useState(settings.primaryColor);

  // Follow what was saved, here or by another owner.
  useEffect(() => {
    setName(settings.name);
    setAddress(settings.slug);
    setPrimaryColor(settings.primaryColor);
  }, [settings.name, settings.slug, settings.primaryColor]);

  if (role !== 'owner') {
    return (
      <Card className={classes.root}>
        <CardContent>
          <Alert severity="info">
            You are a member of {settings.name}. Only an owner can change its
            name, address, logo and theme.
          </Alert>
        </CardContent>
      </Card>
    );
  }

  /** Runs a change, then says `done`. A failure is shown by the context. */
  const save = async (change: () => Promise<void>, done: string) => {
    setSaving(true);
    setSuccessMessage(null);
    try {
      await change();
      setSuccessMessage(done);
    } catch {
      // Shown through `error`.
    } finally {
      setSaving(false);
    }
  };

  /**
   * Saves the name or the address. A refusal, such as a name another
   * organisation has, is shown beside the field. Answers whether it saved.
   */
  const saveIdentity = async (
    change: { name: string } | { slug: string },
    done: string,
  ) => {
    setSaving(true);
    setSuccessMessage(null);
    setRefused(null);
    try {
      await rename(change);
      setSuccessMessage(done);
      return true;
    } catch (caught) {
      setRefused({
        field: 'name' in change ? 'name' : 'slug',
        message: caught instanceof Error ? caught.message : String(caught),
      });
      return false;
    } finally {
      setSaving(false);
    }
  };

  const addressProblem = ADDRESS.test(address) ? null : ADDRESS_RULE;
  const oldAddress = `${window.location.origin}${organisationPath(
    settings.slug,
  )}`;

  const handleAddress = async () => {
    if (
      // eslint-disable-next-line no-alert
      !window.confirm(
        `Change the address to ${window.location.origin}${organisationPath(
          address,
        )}? ${oldAddress} stops working straight away: links and bookmarks to it will not open, and another organisation can take it.`,
      )
    ) {
      return;
    }
    if (await saveIdentity({ slug: address }, 'Address changed')) {
      // A full load: the app has to start again under the new address.
      window.location.assign(
        organisationPath(address, window.location.pathname),
      );
    }
  };
  const handleTheme = (
    changes: { themePreset: PresetId } | { primaryColor: string | null },
    done: string,
  ) => save(() => update(changes), done);

  const handleDelete = async () => {
    if (
      // eslint-disable-next-line no-alert
      !window.confirm(
        `Delete ${settings.name}? Its address, logos and member list go with it. This cannot be undone.`,
      )
    ) {
      return;
    }
    setSaving(true);
    try {
      await remove();
      // Its address is gone: carry on outside any organisation.
      window.location.assign(organisationPath(null));
    } catch {
      // Shown through `error`.
      setSaving(false);
    }
  };

  return (
    <Card className={classes.root}>
      <CardHeader
        title={settings.name}
        subheader="The name, logo and theme people see at your organisation's address"
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

        {/* Name and address */}
        <div className={classes.section}>
          <Typography variant="h6" className={classes.sectionTitle}>
            Name and address
          </Typography>
          <TextField
            fullWidth
            label="Organisation name"
            value={name}
            onChange={e => setName(e.target.value)}
            error={refused?.field === 'name'}
            helperText={
              refused?.field === 'name'
                ? refused.message
                : 'Shown on your sign-in page and in the browser tab, and in the sidebar until you upload a full logo. No two organisations on this portal have the same name.'
            }
            variant="outlined"
            disabled={saving}
            inputProps={{ maxLength: 80 }}
          />
          <Box mt={2}>
            <Button
              variant="contained"
              color="primary"
              startIcon={<SaveIcon />}
              onClick={() => saveIdentity({ name }, 'Name saved')}
              disabled={saving || !name.trim() || name.trim() === settings.name}
            >
              Save name
            </Button>
          </Box>
          <Box mt={2}>
            <TextField
              fullWidth
              label="Address"
              value={address}
              onChange={e => setAddress(e.target.value.toLowerCase())}
              error={addressProblem !== null || refused?.field === 'slug'}
              helperText={
                addressProblem ??
                (refused?.field === 'slug'
                  ? refused.message
                  : `${window.location.origin}${organisationPath(
                      address,
                    )}. Your team signs in at this address and sees the organisation's name, logo and theme. Invite them under Members: people who have not joined are sent elsewhere after signing in.`)
              }
              variant="outlined"
              disabled={saving}
              inputProps={{ maxLength: 40, spellCheck: false }}
            />
          </Box>
          {address !== settings.slug && (
            <Alert severity="warning" style={{ marginTop: 16 }}>
              Changing the address makes {oldAddress} stop working straight
              away. Links and bookmarks to it will not open, nothing sends
              people on to the new address, and another organisation can take
              the old one. Tell your team the new address before you change it.
            </Alert>
          )}
          <Box mt={2}>
            <Button
              variant="outlined"
              color="primary"
              startIcon={<SaveIcon />}
              onClick={handleAddress}
              disabled={
                saving || addressProblem !== null || address === settings.slug
              }
            >
              Change address
            </Button>
          </Box>
        </div>

        <Divider style={{ margin: '24px 0' }} />

        {/* Theme Section */}
        <div className={classes.section}>
          <Typography variant="h6" className={classes.sectionTitle}>
            Theme
          </Typography>
          <div className={classes.presets} role="radiogroup" aria-label="Theme">
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
                  "Primary colour reset to the theme's",
                )
              }
            >
              Use the theme's colour
            </Button>
          </div>
          <Typography className={classes.metadata}>
            Buttons and links use this colour. If it is too pale to read as link
            text, links keep the theme's own colour.
          </Typography>
        </div>

        <Divider style={{ margin: '24px 0' }} />

        {/* Logos */}
        <div className={classes.section}>
          <Typography variant="h6" className={classes.sectionTitle}>
            Logos
          </Typography>
          <Grid container spacing={4}>
            {(['full', 'icon'] as const).map(kind => (
              <LogoField
                key={kind}
                kind={kind}
                url={
                  kind === 'full' ? settings.logoFullUrl : settings.logoIconUrl
                }
                disabled={saving}
                onUpload={file =>
                  save(
                    () => uploadLogo(kind, file),
                    `${LOGOS[kind].name} uploaded`,
                  )
                }
                onRemove={() =>
                  save(() => removeLogo(kind), `${LOGOS[kind].name} removed`)
                }
              />
            ))}
          </Grid>
        </div>

        {/* Delete */}
        <div className={classes.dangerZone}>
          <Typography variant="h6" className={classes.dangerTitle}>
            Delete organisation
          </Typography>
          <Typography variant="body2" paragraph>
            Deletes this organisation, its address, logos and member list.
            Everyone in it is then free to create an organisation or join
            another.
          </Typography>
          <Button
            variant="outlined"
            color="secondary"
            startIcon={<DeleteIcon />}
            onClick={handleDelete}
            disabled={saving}
          >
            Delete organisation
          </Button>
        </div>
      </CardContent>
    </Card>
  );
};
