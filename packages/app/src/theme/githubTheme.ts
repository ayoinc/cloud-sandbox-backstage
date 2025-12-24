import {
  createUnifiedTheme,
  palettes,
  genPageTheme,
  shapes,
} from '@backstage/theme';

/**
 * GitHub Primer Design System Colors
 * @see https://primer.style/primitives/colors
 */
const gitHubColors = {
  // Dark Mode
  dark: {
    canvasDefault: '#0d1117',
    canvasSubtle: '#161b22',
    canvasInset: '#010409',
    border: '#30363d',
    borderMuted: '#21262d',
    textPrimary: '#c9d1d9',
    textSecondary: '#8b949e',
    textMuted: '#6e7681',
    accentGreen: '#238636',
    accentGreenEmphasis: '#2ea043',
    accentBlue: '#1f6feb',
    accentBlueEmphasis: '#388bfd',
    accentPurple: '#8957e5',
    dangerFg: '#f85149',
    warningFg: '#d29922',
    successFg: '#3fb950',
  },
  // Light Mode
  light: {
    canvasDefault: '#ffffff',
    canvasSubtle: '#f6f8fa',
    canvasInset: '#eff2f5',
    border: '#d0d7de',
    borderMuted: '#d8dee4',
    textPrimary: '#24292f',
    textSecondary: '#57606a',
    textMuted: '#6e7781',
    accentGreen: '#1a7f37',
    accentGreenEmphasis: '#2da44e',
    accentBlue: '#0969da',
    accentBlueEmphasis: '#218bff',
    accentPurple: '#8250df',
    dangerFg: '#cf222e',
    warningFg: '#9a6700',
    successFg: '#1a7f37',
  },
};

/**
 * GitHub-inspired Dark Theme
 * Matches the clean, modern aesthetic of GitHub's UI
 */
export const gitHubDarkTheme = createUnifiedTheme({
  palette: {
    ...palettes.dark,
    mode: 'dark',
    primary: {
      main: gitHubColors.dark.accentGreen,
      light: gitHubColors.dark.accentGreenEmphasis,
      dark: '#196c2e',
    },
    secondary: {
      main: gitHubColors.dark.accentBlue,
      light: gitHubColors.dark.accentBlueEmphasis,
      dark: '#1158c7',
    },
    background: {
      default: gitHubColors.dark.canvasDefault,
      paper: gitHubColors.dark.canvasSubtle,
    },
    text: {
      primary: gitHubColors.dark.textPrimary,
      secondary: gitHubColors.dark.textSecondary,
    },
    navigation: {
      background: gitHubColors.dark.canvasSubtle,
      indicator: gitHubColors.dark.accentGreen,
      color: gitHubColors.dark.textSecondary,
      selectedColor: gitHubColors.dark.textPrimary,
      navItem: {
        hoverBackground: gitHubColors.dark.borderMuted,
      },
      submenu: {
        background: gitHubColors.dark.canvasDefault,
      },
    },
    error: {
      main: gitHubColors.dark.dangerFg,
    },
    warning: {
      main: gitHubColors.dark.warningFg,
    },
    success: {
      main: gitHubColors.dark.successFg,
    },
    info: {
      main: gitHubColors.dark.accentBlue,
    },
    divider: gitHubColors.dark.border,
  },
  fontFamily:
    '-apple-system, BlinkMacSystemFont, "Segoe UI", "Noto Sans", Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji"',
  defaultPageTheme: 'home',
  pageTheme: {
    home: genPageTheme({
      colors: [gitHubColors.dark.canvasSubtle, gitHubColors.dark.canvasDefault],
      shape: shapes.wave,
    }),
    documentation: genPageTheme({
      colors: [gitHubColors.dark.accentBlue, gitHubColors.dark.canvasDefault],
      shape: shapes.wave2,
    }),
    tool: genPageTheme({
      colors: [gitHubColors.dark.accentPurple, gitHubColors.dark.canvasDefault],
      shape: shapes.round,
    }),
    service: genPageTheme({
      colors: [gitHubColors.dark.accentGreen, gitHubColors.dark.canvasDefault],
      shape: shapes.wave,
    }),
    website: genPageTheme({
      colors: [gitHubColors.dark.accentBlue, gitHubColors.dark.canvasDefault],
      shape: shapes.wave,
    }),
    library: genPageTheme({
      colors: [gitHubColors.dark.accentPurple, gitHubColors.dark.canvasDefault],
      shape: shapes.wave,
    }),
    other: genPageTheme({
      colors: [
        gitHubColors.dark.textSecondary,
        gitHubColors.dark.canvasDefault,
      ],
      shape: shapes.wave,
    }),
    app: genPageTheme({
      colors: [gitHubColors.dark.accentGreen, gitHubColors.dark.canvasDefault],
      shape: shapes.wave,
    }),
    apis: genPageTheme({
      colors: [gitHubColors.dark.accentBlue, gitHubColors.dark.canvasDefault],
      shape: shapes.wave2,
    }),
  },
  components: {
    BackstageHeader: {
      styleOverrides: {
        header: {
          backgroundImage: 'none',
          backgroundColor: gitHubColors.dark.canvasSubtle,
          borderBottom: `1px solid ${gitHubColors.dark.border}`,
          boxShadow: 'none',
        },
        title: {
          color: gitHubColors.dark.textPrimary,
        },
        subtitle: {
          color: gitHubColors.dark.textSecondary,
        },
      },
    },
    BackstageHeaderTabs: {
      styleOverrides: {
        defaultTab: {
          color: gitHubColors.dark.textSecondary,
          '&:hover': {
            color: gitHubColors.dark.textPrimary,
          },
        },
        selected: {
          color: gitHubColors.dark.textPrimary,
        },
        tabsWrapper: {
          borderBottom: `1px solid ${gitHubColors.dark.border}`,
        },
      },
    },
    BackstageSidebar: {
      styleOverrides: {
        drawer: {
          backgroundColor: gitHubColors.dark.canvasSubtle,
          borderRight: `1px solid ${gitHubColors.dark.border}`,
        },
      },
    },
    BackstageSidebarItem: {
      styleOverrides: {
        root: {
          color: gitHubColors.dark.textSecondary,
          '&:hover': {
            backgroundColor: gitHubColors.dark.borderMuted,
            color: gitHubColors.dark.textPrimary,
          },
        },
        selected: {
          backgroundColor: gitHubColors.dark.borderMuted,
          color: gitHubColors.dark.textPrimary,
          '&::before': {
            backgroundColor: gitHubColors.dark.accentGreen,
          },
        },
        label: {
          color: 'inherit',
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          backgroundColor: gitHubColors.dark.canvasSubtle,
          borderRadius: 6,
          border: `1px solid ${gitHubColors.dark.border}`,
        },
        elevation1: {
          boxShadow: '0 1px 0 rgba(27,31,35,0.04)',
        },
        elevation2: {
          boxShadow: '0 3px 6px rgba(0,0,0,0.12)',
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          backgroundColor: gitHubColors.dark.canvasSubtle,
          borderRadius: 6,
          border: `1px solid ${gitHubColors.dark.border}`,
        },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: {
          textTransform: 'none',
          fontWeight: 500,
          borderRadius: 6,
        },
        contained: {
          boxShadow: 'none',
          '&:hover': {
            boxShadow: 'none',
          },
        },
        containedPrimary: {
          backgroundColor: gitHubColors.dark.accentGreen,
          '&:hover': {
            backgroundColor: gitHubColors.dark.accentGreenEmphasis,
          },
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: {
          borderRadius: 16,
        },
      },
    },
    MuiTableRow: {
      styleOverrides: {
        root: {
          '&:hover': {
            backgroundColor: gitHubColors.dark.borderMuted,
          },
        },
      },
    },
    MuiTableCell: {
      styleOverrides: {
        head: {
          fontWeight: 600,
          borderBottomColor: gitHubColors.dark.border,
        },
        body: {
          borderBottomColor: gitHubColors.dark.border,
        },
      },
    },
    MuiLink: {
      styleOverrides: {
        root: {
          color: gitHubColors.dark.accentBlueEmphasis,
        },
      },
    },
  },
});

/**
 * GitHub-inspired Light Theme
 */
export const gitHubLightTheme = createUnifiedTheme({
  palette: {
    ...palettes.light,
    mode: 'light',
    primary: {
      main: gitHubColors.light.accentGreen,
      light: gitHubColors.light.accentGreenEmphasis,
      dark: '#116329',
    },
    secondary: {
      main: gitHubColors.light.accentBlue,
      light: gitHubColors.light.accentBlueEmphasis,
      dark: '#0550ae',
    },
    background: {
      default: gitHubColors.light.canvasDefault,
      paper: gitHubColors.light.canvasSubtle,
    },
    text: {
      primary: gitHubColors.light.textPrimary,
      secondary: gitHubColors.light.textSecondary,
    },
    navigation: {
      background: gitHubColors.light.canvasSubtle,
      indicator: gitHubColors.light.accentGreen,
      color: gitHubColors.light.textSecondary,
      selectedColor: gitHubColors.light.textPrimary,
      navItem: {
        hoverBackground: gitHubColors.light.borderMuted,
      },
      submenu: {
        background: gitHubColors.light.canvasDefault,
      },
    },
    error: {
      main: gitHubColors.light.dangerFg,
    },
    warning: {
      main: gitHubColors.light.warningFg,
    },
    success: {
      main: gitHubColors.light.successFg,
    },
    info: {
      main: gitHubColors.light.accentBlue,
    },
    divider: gitHubColors.light.border,
  },
  fontFamily:
    '-apple-system, BlinkMacSystemFont, "Segoe UI", "Noto Sans", Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji"',
  defaultPageTheme: 'home',
  pageTheme: {
    home: genPageTheme({
      colors: [
        gitHubColors.light.canvasSubtle,
        gitHubColors.light.canvasDefault,
      ],
      shape: shapes.wave,
    }),
    documentation: genPageTheme({
      colors: [gitHubColors.light.accentBlue, gitHubColors.light.canvasDefault],
      shape: shapes.wave2,
    }),
    tool: genPageTheme({
      colors: [
        gitHubColors.light.accentPurple,
        gitHubColors.light.canvasDefault,
      ],
      shape: shapes.round,
    }),
    service: genPageTheme({
      colors: [
        gitHubColors.light.accentGreen,
        gitHubColors.light.canvasDefault,
      ],
      shape: shapes.wave,
    }),
    website: genPageTheme({
      colors: [gitHubColors.light.accentBlue, gitHubColors.light.canvasDefault],
      shape: shapes.wave,
    }),
    library: genPageTheme({
      colors: [
        gitHubColors.light.accentPurple,
        gitHubColors.light.canvasDefault,
      ],
      shape: shapes.wave,
    }),
    other: genPageTheme({
      colors: [
        gitHubColors.light.textSecondary,
        gitHubColors.light.canvasDefault,
      ],
      shape: shapes.wave,
    }),
    app: genPageTheme({
      colors: [
        gitHubColors.light.accentGreen,
        gitHubColors.light.canvasDefault,
      ],
      shape: shapes.wave,
    }),
    apis: genPageTheme({
      colors: [gitHubColors.light.accentBlue, gitHubColors.light.canvasDefault],
      shape: shapes.wave2,
    }),
  },
  components: {
    BackstageHeader: {
      styleOverrides: {
        header: {
          backgroundImage: 'none',
          backgroundColor: gitHubColors.light.canvasSubtle,
          borderBottom: `1px solid ${gitHubColors.light.border}`,
          boxShadow: 'none',
        },
        title: {
          color: gitHubColors.light.textPrimary,
        },
        subtitle: {
          color: gitHubColors.light.textSecondary,
        },
      },
    },
    BackstageHeaderTabs: {
      styleOverrides: {
        defaultTab: {
          color: gitHubColors.light.textSecondary,
          '&:hover': {
            color: gitHubColors.light.textPrimary,
          },
        },
        selected: {
          color: gitHubColors.light.textPrimary,
        },
        tabsWrapper: {
          borderBottom: `1px solid ${gitHubColors.light.border}`,
        },
      },
    },
    BackstageSidebar: {
      styleOverrides: {
        drawer: {
          backgroundColor: gitHubColors.light.canvasSubtle,
          borderRight: `1px solid ${gitHubColors.light.border}`,
        },
      },
    },
    BackstageSidebarItem: {
      styleOverrides: {
        root: {
          color: gitHubColors.light.textSecondary,
          '&:hover': {
            backgroundColor: gitHubColors.light.borderMuted,
            color: gitHubColors.light.textPrimary,
          },
        },
        selected: {
          backgroundColor: gitHubColors.light.borderMuted,
          color: gitHubColors.light.textPrimary,
          '&::before': {
            backgroundColor: gitHubColors.light.accentGreen,
          },
        },
        label: {
          color: 'inherit',
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          backgroundColor: gitHubColors.light.canvasSubtle,
          borderRadius: 6,
          border: `1px solid ${gitHubColors.light.border}`,
        },
        elevation1: {
          boxShadow: '0 1px 0 rgba(27,31,35,0.04)',
        },
        elevation2: {
          boxShadow: '0 3px 6px rgba(0,0,0,0.12)',
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          backgroundColor: gitHubColors.light.canvasSubtle,
          borderRadius: 6,
          border: `1px solid ${gitHubColors.light.border}`,
        },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: {
          textTransform: 'none',
          fontWeight: 500,
          borderRadius: 6,
        },
        contained: {
          boxShadow: 'none',
          '&:hover': {
            boxShadow: 'none',
          },
        },
        containedPrimary: {
          backgroundColor: gitHubColors.light.accentGreen,
          color: '#ffffff',
          '&:hover': {
            backgroundColor: gitHubColors.light.accentGreenEmphasis,
          },
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: {
          borderRadius: 16,
        },
      },
    },
    MuiTableRow: {
      styleOverrides: {
        root: {
          '&:hover': {
            backgroundColor: gitHubColors.light.borderMuted,
          },
        },
      },
    },
    MuiTableCell: {
      styleOverrides: {
        head: {
          fontWeight: 600,
          borderBottomColor: gitHubColors.light.border,
        },
        body: {
          borderBottomColor: gitHubColors.light.border,
        },
      },
    },
    MuiLink: {
      styleOverrides: {
        root: {
          color: gitHubColors.light.accentBlue,
        },
      },
    },
  },
});
