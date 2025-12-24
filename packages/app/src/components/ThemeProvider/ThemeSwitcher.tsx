import React from "react";
import {
  makeStyles,
  IconButton,
  Menu,
  MenuItem,
  ListItemIcon,
  ListItemText,
  Divider,
  Typography,

} from "@material-ui/core";
import Brightness4Icon from "@material-ui/icons/Brightness4";
import Brightness7Icon from "@material-ui/icons/Brightness7";
import SettingsBrightnessIcon from "@material-ui/icons/SettingsBrightness";
import CheckIcon from "@material-ui/icons/Check";
import PaletteIcon from "@material-ui/icons/Palette";
import { useThemeContext } from "./ThemeProvider";

const useStyles = makeStyles((theme) => ({
  menuPaper: {
    minWidth: 220,
  },
  sectionTitle: {
    padding: theme.spacing(1, 2, 0.5),
    fontSize: "0.75rem",
    fontWeight: 600,
    textTransform: "uppercase",
    color: theme.palette.text.secondary,
    letterSpacing: "0.5px",
  },
  presetItem: {
    paddingLeft: theme.spacing(2),
  },
  presetDescription: {
    fontSize: "0.75rem",
    color: theme.palette.text.secondary,
  },
  iconButton: {
    color: "inherit",
  },
}));

export const ThemeSwitcher: React.FC = () => {
  const classes = useStyles();
  const { themeMode, setThemeMode, themePresetId, setThemePresetId, availablePresets, effectiveMode } = useThemeContext();
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);

  const handleOpen = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  const handleModeChange = (mode: "light" | "dark" | "system") => {
    setThemeMode(mode);
  };

  const handlePresetChange = (presetId: string) => {
    setThemePresetId(presetId);
    handleClose();
  };

  const getModeIcon = () => {
    if (themeMode === "system") return <SettingsBrightnessIcon />;
    return effectiveMode === "dark" ? <Brightness4Icon /> : <Brightness7Icon />;
  };

  return (
    <>
      <IconButton
        className={classes.iconButton}
        onClick={handleOpen}
        aria-label="Theme settings"
        size="small"
      >
        {getModeIcon()}
      </IconButton>
      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleClose}
        classes={{ paper: classes.menuPaper }}
        anchorOrigin={{ vertical: "bottom", horizontal: "right" }}
        transformOrigin={{ vertical: "top", horizontal: "right" }}
        getContentAnchorEl={null}
      >
        <Typography className={classes.sectionTitle}>Appearance</Typography>
        <MenuItem onClick={() => handleModeChange("light")}>
          <ListItemIcon>
            {themeMode === "light" ? <CheckIcon fontSize="small" /> : <Brightness7Icon fontSize="small" />}
          </ListItemIcon>
          <ListItemText primary="Light" />
        </MenuItem>
        <MenuItem onClick={() => handleModeChange("dark")}>
          <ListItemIcon>
            {themeMode === "dark" ? <CheckIcon fontSize="small" /> : <Brightness4Icon fontSize="small" />}
          </ListItemIcon>
          <ListItemText primary="Dark" />
        </MenuItem>
        <MenuItem onClick={() => handleModeChange("system")}>
          <ListItemIcon>
            {themeMode === "system" ? <CheckIcon fontSize="small" /> : <SettingsBrightnessIcon fontSize="small" />}
          </ListItemIcon>
          <ListItemText primary="System" />
        </MenuItem>

        <Divider style={{ margin: "8px 0" }} />

        <Typography className={classes.sectionTitle}>Theme</Typography>
        {availablePresets.map((preset) => (
          <MenuItem
            key={preset.id}
            onClick={() => handlePresetChange(preset.id)}
            className={classes.presetItem}
          >
            <ListItemIcon>
              {themePresetId === preset.id ? <CheckIcon fontSize="small" /> : <PaletteIcon fontSize="small" />}
            </ListItemIcon>
            <ListItemText
              primary={preset.name}
              secondary={preset.description}
              secondaryTypographyProps={{ className: classes.presetDescription }}
            />
          </MenuItem>
        ))}
      </Menu>
    </>
  );
};

export default ThemeSwitcher;
