import {
  createUnifiedTheme,
  palettes,
  genPageTheme,
  shapes,
} from "@backstage/theme";

/**
 * Cloud Sandbox Theme Collection
 * 
 * Includes:
 * 1. Backstage Default - Stock Backstage theme
 * 2. Liquid Glass - Apple-inspired glassmorphism  
 * 3. GitHub - Primer design system
 * 4. Nord - Arctic elegant palette
 * 5. Dracula - Popular dark theme
 * 6. Catppuccin - Soothing pastel
 */

export interface ThemePreset {
  id: string;
  name: string;
  description: string;
  light: ReturnType<typeof createUnifiedTheme>;
  dark: ReturnType<typeof createUnifiedTheme>;
}

// Shared component styles for polished alerts and notifications
const createAlertStyles = (mode: "light" | "dark") => ({
  MuiAlert: {
    styleOverrides: {
      root: {
        borderRadius: 12,
        backdropFilter: "blur(20px)",
        border: mode === "dark" ? "1px solid rgba(255,255,255,0.1)" : "1px solid rgba(0,0,0,0.08)",
        boxShadow: mode === "dark" 
          ? "0 8px 32px rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.1)"
          : "0 8px 32px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.8)",
        padding: "12px 16px",
        "& .MuiAlert-icon": { opacity: 1, padding: "4px 0" },
        "& .MuiAlert-message": { fontWeight: 500 },
      },
      standardSuccess: {
        backgroundColor: mode === "dark" ? "rgba(34, 197, 94, 0.15)" : "rgba(34, 197, 94, 0.12)",
        color: mode === "dark" ? "#4ade80" : "#15803d",
        "& .MuiAlert-icon": { color: mode === "dark" ? "#4ade80" : "#16a34a" },
      },
      standardError: {
        backgroundColor: mode === "dark" ? "rgba(239, 68, 68, 0.15)" : "rgba(239, 68, 68, 0.12)",
        color: mode === "dark" ? "#f87171" : "#dc2626",
        "& .MuiAlert-icon": { color: mode === "dark" ? "#f87171" : "#ef4444" },
      },
      standardWarning: {
        backgroundColor: mode === "dark" ? "rgba(245, 158, 11, 0.15)" : "rgba(245, 158, 11, 0.12)",
        color: mode === "dark" ? "#fbbf24" : "#d97706",
        "& .MuiAlert-icon": { color: mode === "dark" ? "#fbbf24" : "#f59e0b" },
      },
      standardInfo: {
        backgroundColor: mode === "dark" ? "rgba(59, 130, 246, 0.15)" : "rgba(59, 130, 246, 0.12)",
        color: mode === "dark" ? "#60a5fa" : "#2563eb",
        "& .MuiAlert-icon": { color: mode === "dark" ? "#60a5fa" : "#3b82f6" },
      },
    },
  },
  MuiSnackbar: {
    styleOverrides: {
      root: {
        "& .MuiPaper-root": { borderRadius: 12, backdropFilter: "blur(20px)" },
      },
    },
  },
  MuiSnackbarContent: {
    styleOverrides: {
      root: {
        borderRadius: 12,
        backdropFilter: "blur(20px)",
        backgroundColor: mode === "dark" ? "rgba(30, 41, 59, 0.95)" : "rgba(255, 255, 255, 0.95)",
        color: mode === "dark" ? "#f1f5f9" : "#1e293b",
        boxShadow: mode === "dark"
          ? "0 8px 32px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.1)"
          : "0 8px 32px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.8)",
        border: mode === "dark" ? "1px solid rgba(255,255,255,0.1)" : "1px solid rgba(0,0,0,0.08)",
        fontWeight: 500,
      },
    },
  },
});

// =============================================================================
// 1. BACKSTAGE DEFAULT - Stock Backstage Theme
// =============================================================================
const backstageDefaultLight = createUnifiedTheme({
  palette: {
    ...palettes.light,
  },
  defaultPageTheme: "home",
  pageTheme: {
    home: genPageTheme({ colors: ["#005B4B", "#00796B"], shape: shapes.wave }),
    documentation: genPageTheme({ colors: ["#1976D2", "#42A5F5"], shape: shapes.wave2 }),
    tool: genPageTheme({ colors: ["#512DA8", "#7C4DFF"], shape: shapes.round }),
    service: genPageTheme({ colors: ["#00838F", "#00BCD4"], shape: shapes.wave }),
    website: genPageTheme({ colors: ["#C2185B", "#E91E63"], shape: shapes.wave }),
    library: genPageTheme({ colors: ["#388E3C", "#4CAF50"], shape: shapes.wave2 }),
    other: genPageTheme({ colors: ["#616161", "#757575"], shape: shapes.wave }),
    app: genPageTheme({ colors: ["#0277BD", "#03A9F4"], shape: shapes.wave }),
    apis: genPageTheme({ colors: ["#558B2F", "#8BC34A"], shape: shapes.wave2 }),
  },
});

const backstageDefaultDark = createUnifiedTheme({
  palette: {
    ...palettes.dark,
  },
  defaultPageTheme: "home",
  pageTheme: {
    home: genPageTheme({ colors: ["#004D40", "#00695C"], shape: shapes.wave }),
    documentation: genPageTheme({ colors: ["#1565C0", "#1976D2"], shape: shapes.wave2 }),
    tool: genPageTheme({ colors: ["#4527A0", "#673AB7"], shape: shapes.round }),
    service: genPageTheme({ colors: ["#006064", "#00838F"], shape: shapes.wave }),
    website: genPageTheme({ colors: ["#AD1457", "#C2185B"], shape: shapes.wave }),
    library: genPageTheme({ colors: ["#2E7D32", "#388E3C"], shape: shapes.wave2 }),
    other: genPageTheme({ colors: ["#424242", "#616161"], shape: shapes.wave }),
    app: genPageTheme({ colors: ["#01579B", "#0277BD"], shape: shapes.wave }),
    apis: genPageTheme({ colors: ["#33691E", "#558B2F"], shape: shapes.wave2 }),
  },
});

// =============================================================================
// 2. LIQUID GLASS - Apple-inspired Glassmorphism (iOS 26 / macOS 26 style)
// Features: Backdrop blur, translucency, specular highlights, depth layers
// =============================================================================
const liquidGlassLight = createUnifiedTheme({
  palette: {
    ...palettes.light,
    primary: { main: "#007AFF" },
    secondary: { main: "#5856D6" },
    error: { main: "#FF3B30" },
    warning: { main: "#FF9500" },
    info: { main: "#5AC8FA" },
    success: { main: "#34C759" },
    background: { 
      default: "#F2F2F7", 
      paper: "rgba(255, 255, 255, 0.72)" 
    },
    navigation: {
      background: "rgba(22, 22, 23, 0.92)",
      indicator: "#007AFF",
      color: "rgba(255, 255, 255, 0.6)",
      selectedColor: "#FFFFFF",
      navItem: { hoverBackground: "rgba(255, 255, 255, 0.08)" },
    },
  },
  defaultPageTheme: "home",
  pageTheme: {
    home: genPageTheme({ colors: ["#007AFF", "#5856D6"], shape: shapes.wave }),
    documentation: genPageTheme({ colors: ["#5AC8FA", "#007AFF"], shape: shapes.wave2 }),
    tool: genPageTheme({ colors: ["#5856D6", "#AF52DE"], shape: shapes.round }),
    service: genPageTheme({ colors: ["#007AFF", "#32ADE6"], shape: shapes.wave }),
    website: genPageTheme({ colors: ["#FF2D55", "#FF375F"], shape: shapes.wave }),
    library: genPageTheme({ colors: ["#34C759", "#30D158"], shape: shapes.wave2 }),
    other: genPageTheme({ colors: ["#8E8E93", "#AEAEB2"], shape: shapes.wave }),
    app: genPageTheme({ colors: ["#007AFF", "#5856D6"], shape: shapes.wave }),
    apis: genPageTheme({ colors: ["#32ADE6", "#5AC8FA"], shape: shapes.wave2 }),
  },
  fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", sans-serif',
  components: {
    ...createAlertStyles("light"),
    MuiCssBaseline: {
      styleOverrides: {
        body: {
          // Smooth font rendering for glass effect
          WebkitFontSmoothing: "antialiased",
          MozOsxFontSmoothing: "grayscale",
        },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: { 
          borderRadius: 12, 
          textTransform: "none" as const, 
          fontWeight: 600,
          backdropFilter: "blur(20px)",
          transition: "all 0.2s cubic-bezier(0.25, 0.1, 0.25, 1)",
        },
        contained: {
          background: "linear-gradient(180deg, rgba(0, 122, 255, 0.9) 0%, rgba(0, 102, 224, 0.95) 100%)",
          boxShadow: "0 2px 8px rgba(0, 122, 255, 0.35), inset 0 1px 0 rgba(255,255,255,0.2)",
          "&:hover": { 
            boxShadow: "0 4px 16px rgba(0, 122, 255, 0.45), inset 0 1px 0 rgba(255,255,255,0.25)",
            transform: "translateY(-1px)",
          },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: { 
          borderRadius: 20, 
          backdropFilter: "blur(40px) saturate(180%)",
          backgroundColor: "rgba(255, 255, 255, 0.72)",
          border: "1px solid rgba(255, 255, 255, 0.5)",
          boxShadow: "0 8px 32px rgba(0, 0, 0, 0.08), inset 0 1px 0 rgba(255,255,255,0.8)",
          // Specular highlight effect
          backgroundImage: "linear-gradient(180deg, rgba(255,255,255,0.4) 0%, rgba(255,255,255,0) 40%)",
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: { 
          backdropFilter: "blur(40px) saturate(180%)",
          backgroundImage: "none",
        },
        rounded: { borderRadius: 16 },
        elevation1: {
          boxShadow: "0 4px 16px rgba(0, 0, 0, 0.08), inset 0 1px 0 rgba(255,255,255,0.8)",
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: { 
          borderRadius: 8, 
          fontWeight: 600,
          backdropFilter: "blur(10px)",
        },
      },
    },
    MuiTooltip: {
      styleOverrides: {
        tooltip: {
          borderRadius: 10,
          backdropFilter: "blur(20px) saturate(180%)",
          backgroundColor: "rgba(22, 22, 23, 0.88)",
          boxShadow: "0 4px 16px rgba(0, 0, 0, 0.2)",
          fontSize: "13px",
          fontWeight: 500,
          padding: "8px 12px",
        },
      },
    },
  },
});

const liquidGlassDark = createUnifiedTheme({
  palette: {
    ...palettes.dark,
    primary: { main: "#0A84FF" },
    secondary: { main: "#5E5CE6" },
    error: { main: "#FF453A" },
    warning: { main: "#FF9F0A" },
    info: { main: "#64D2FF" },
    success: { main: "#30D158" },
    background: { 
      default: "#000000", 
      paper: "rgba(28, 28, 30, 0.72)" 
    },
    navigation: {
      background: "rgba(22, 22, 23, 0.95)",
      indicator: "#0A84FF",
      color: "rgba(255, 255, 255, 0.55)",
      selectedColor: "#FFFFFF",
      navItem: { hoverBackground: "rgba(255, 255, 255, 0.06)" },
    },
  },
  defaultPageTheme: "home",
  pageTheme: {
    home: genPageTheme({ colors: ["#0A84FF", "#5E5CE6"], shape: shapes.wave }),
    documentation: genPageTheme({ colors: ["#64D2FF", "#0A84FF"], shape: shapes.wave2 }),
    tool: genPageTheme({ colors: ["#5E5CE6", "#BF5AF2"], shape: shapes.round }),
    service: genPageTheme({ colors: ["#0A84FF", "#32D74B"], shape: shapes.wave }),
    website: genPageTheme({ colors: ["#FF375F", "#FF2D55"], shape: shapes.wave }),
    library: genPageTheme({ colors: ["#30D158", "#32D74B"], shape: shapes.wave2 }),
    other: genPageTheme({ colors: ["#636366", "#8E8E93"], shape: shapes.wave }),
    app: genPageTheme({ colors: ["#0A84FF", "#5E5CE6"], shape: shapes.wave }),
    apis: genPageTheme({ colors: ["#32D74B", "#64D2FF"], shape: shapes.wave2 }),
  },
  fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", sans-serif',
  components: {
    ...createAlertStyles("dark"),
    MuiCssBaseline: {
      styleOverrides: {
        body: {
          WebkitFontSmoothing: "antialiased",
          MozOsxFontSmoothing: "grayscale",
        },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: { 
          borderRadius: 12, 
          textTransform: "none" as const, 
          fontWeight: 600,
          backdropFilter: "blur(20px)",
          transition: "all 0.2s cubic-bezier(0.25, 0.1, 0.25, 1)",
        },
        contained: {
          background: "linear-gradient(180deg, rgba(10, 132, 255, 0.9) 0%, rgba(0, 102, 224, 0.95) 100%)",
          boxShadow: "0 2px 8px rgba(10, 132, 255, 0.4), inset 0 1px 0 rgba(255,255,255,0.15)",
          "&:hover": { 
            boxShadow: "0 4px 16px rgba(10, 132, 255, 0.5), inset 0 1px 0 rgba(255,255,255,0.2)",
            transform: "translateY(-1px)",
          },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: { 
          borderRadius: 20, 
          backdropFilter: "blur(40px) saturate(180%)",
          backgroundColor: "rgba(28, 28, 30, 0.72)",
          border: "1px solid rgba(255, 255, 255, 0.08)",
          boxShadow: "0 8px 32px rgba(0, 0, 0, 0.4), inset 0 1px 0 rgba(255,255,255,0.05)",
          backgroundImage: "linear-gradient(180deg, rgba(255,255,255,0.08) 0%, rgba(255,255,255,0) 40%)",
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: { 
          backdropFilter: "blur(40px) saturate(180%)",
          backgroundImage: "none",
        },
        rounded: { borderRadius: 16 },
        elevation1: {
          boxShadow: "0 4px 16px rgba(0, 0, 0, 0.3), inset 0 1px 0 rgba(255,255,255,0.05)",
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: { 
          borderRadius: 8, 
          fontWeight: 600,
          backdropFilter: "blur(10px)",
        },
      },
    },
    MuiTooltip: {
      styleOverrides: {
        tooltip: {
          borderRadius: 10,
          backdropFilter: "blur(20px) saturate(180%)",
          backgroundColor: "rgba(60, 60, 67, 0.95)",
          boxShadow: "0 4px 16px rgba(0, 0, 0, 0.4)",
          fontSize: "13px",
          fontWeight: 500,
          padding: "8px 12px",
        },
      },
    },
  },
});

// =============================================================================
// 3. GITHUB - Primer Design System (Authentic)
// =============================================================================
const githubLight = createUnifiedTheme({
  palette: {
    ...palettes.light,
    primary: { main: "#0969DA" },
    secondary: { main: "#8250DF" },
    error: { main: "#CF222E" },
    warning: { main: "#9A6700" },
    info: { main: "#0969DA" },
    success: { main: "#1A7F37" },
    background: { default: "#F6F8FA", paper: "#FFFFFF" },
    navigation: {
      background: "#24292F",
      indicator: "#FD8C73",
      color: "#8B949E",
      selectedColor: "#FFFFFF",
      navItem: { hoverBackground: "rgba(177, 186, 196, 0.12)" },
    },
  },
  defaultPageTheme: "home",
  pageTheme: {
    home: genPageTheme({ colors: ["#0969DA", "#218BFF"], shape: shapes.wave }),
    documentation: genPageTheme({ colors: ["#8250DF", "#A475F9"], shape: shapes.wave2 }),
    tool: genPageTheme({ colors: ["#1A7F37", "#2DA44E"], shape: shapes.round }),
    service: genPageTheme({ colors: ["#0969DA", "#218BFF"], shape: shapes.wave }),
    website: genPageTheme({ colors: ["#8250DF", "#A475F9"], shape: shapes.wave }),
    library: genPageTheme({ colors: ["#9A6700", "#BF8700"], shape: shapes.wave2 }),
    other: genPageTheme({ colors: ["#57606A", "#6E7781"], shape: shapes.wave }),
    app: genPageTheme({ colors: ["#0969DA", "#218BFF"], shape: shapes.wave }),
    apis: genPageTheme({ colors: ["#1A7F37", "#2DA44E"], shape: shapes.wave2 }),
  },
  fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", "Noto Sans", Helvetica, Arial, sans-serif',
  components: {
    ...createAlertStyles("light"),
    MuiButton: {
      styleOverrides: {
        root: { 
          borderRadius: 6, 
          textTransform: "none" as const, 
          fontWeight: 600,
          fontSize: "14px",
          padding: "5px 16px",
          border: "1px solid rgba(27, 31, 36, 0.15)",
          boxShadow: "0 1px 0 rgba(27, 31, 36, 0.04)",
        },
        contained: {
          backgroundColor: "#2DA44E",
          color: "#FFFFFF",
          border: "1px solid rgba(27, 31, 36, 0.15)",
          "&:hover": { backgroundColor: "#2C974B" },
        },
        outlined: {
          backgroundColor: "#F6F8FA",
          borderColor: "rgba(27, 31, 36, 0.15)",
          "&:hover": { backgroundColor: "#F3F4F6", borderColor: "rgba(27, 31, 36, 0.15)" },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: { 
          borderRadius: 6, 
          border: "1px solid #D0D7DE",
          boxShadow: "none",
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        rounded: { borderRadius: 6 },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: { borderRadius: 20, fontWeight: 600, fontSize: "12px" },
        colorPrimary: { backgroundColor: "#DDF4FF", color: "#0969DA" },
        colorSecondary: { backgroundColor: "#FBEFFF", color: "#8250DF" },
      },
    },
  },
});

const githubDark = createUnifiedTheme({
  palette: {
    ...palettes.dark,
    primary: { main: "#58A6FF" },
    secondary: { main: "#BC8CFF" },
    error: { main: "#F85149" },
    warning: { main: "#D29922" },
    info: { main: "#58A6FF" },
    success: { main: "#3FB950" },
    background: { default: "#0D1117", paper: "#161B22" },
    navigation: {
      background: "#010409",
      indicator: "#FD8C73",
      color: "#8B949E",
      selectedColor: "#F0F6FC",
      navItem: { hoverBackground: "rgba(177, 186, 196, 0.12)" },
    },
  },
  defaultPageTheme: "home",
  pageTheme: {
    home: genPageTheme({ colors: ["#1F6FEB", "#388BFD"], shape: shapes.wave }),
    documentation: genPageTheme({ colors: ["#8957E5", "#A371F7"], shape: shapes.wave2 }),
    tool: genPageTheme({ colors: ["#238636", "#2EA043"], shape: shapes.round }),
    service: genPageTheme({ colors: ["#1F6FEB", "#388BFD"], shape: shapes.wave }),
    website: genPageTheme({ colors: ["#8957E5", "#A371F7"], shape: shapes.wave }),
    library: genPageTheme({ colors: ["#9E6A03", "#BB8009"], shape: shapes.wave2 }),
    other: genPageTheme({ colors: ["#484F58", "#6E7681"], shape: shapes.wave }),
    app: genPageTheme({ colors: ["#1F6FEB", "#388BFD"], shape: shapes.wave }),
    apis: genPageTheme({ colors: ["#238636", "#2EA043"], shape: shapes.wave2 }),
  },
  fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", "Noto Sans", Helvetica, Arial, sans-serif',
  components: {
    ...createAlertStyles("dark"),
    MuiButton: {
      styleOverrides: {
        root: { 
          borderRadius: 6, 
          textTransform: "none" as const, 
          fontWeight: 600,
          fontSize: "14px",
          padding: "5px 16px",
          border: "1px solid #30363D",
        },
        contained: {
          backgroundColor: "#238636",
          color: "#FFFFFF",
          border: "1px solid rgba(240, 246, 252, 0.1)",
          "&:hover": { backgroundColor: "#2EA043" },
        },
        outlined: {
          backgroundColor: "#21262D",
          borderColor: "#30363D",
          color: "#C9D1D9",
          "&:hover": { backgroundColor: "#30363D", borderColor: "#8B949E" },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: { 
          borderRadius: 6, 
          border: "1px solid #30363D",
          boxShadow: "none",
          backgroundImage: "none",
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: { backgroundImage: "none" },
        rounded: { borderRadius: 6 },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: { borderRadius: 20, fontWeight: 600, fontSize: "12px" },
        colorPrimary: { backgroundColor: "rgba(56, 139, 253, 0.15)", color: "#58A6FF" },
        colorSecondary: { backgroundColor: "rgba(163, 113, 247, 0.15)", color: "#BC8CFF" },
      },
    },
  },
});

// =============================================================================
// 4. NORD - Elegant Arctic Palette (Developer Favorite)
// =============================================================================
const nordLight = createUnifiedTheme({
  palette: {
    ...palettes.light,
    primary: { main: "#5E81AC" },
    secondary: { main: "#81A1C1" },
    error: { main: "#BF616A" },
    warning: { main: "#D08770" },
    info: { main: "#88C0D0" },
    success: { main: "#A3BE8C" },
    background: { default: "#ECEFF4", paper: "#FFFFFF" },
    navigation: {
      background: "#2E3440",
      indicator: "#88C0D0",
      color: "#D8DEE9",
      selectedColor: "#ECEFF4",
      navItem: { hoverBackground: "rgba(136, 192, 208, 0.12)" },
    },
  },
  defaultPageTheme: "home",
  pageTheme: {
    home: genPageTheme({ colors: ["#5E81AC", "#81A1C1"], shape: shapes.wave }),
    documentation: genPageTheme({ colors: ["#88C0D0", "#8FBCBB"], shape: shapes.wave2 }),
    tool: genPageTheme({ colors: ["#A3BE8C", "#8FBCBB"], shape: shapes.round }),
    service: genPageTheme({ colors: ["#5E81AC", "#81A1C1"], shape: shapes.wave }),
    website: genPageTheme({ colors: ["#B48EAD", "#A3BE8C"], shape: shapes.wave }),
    library: genPageTheme({ colors: ["#A3BE8C", "#8FBCBB"], shape: shapes.wave2 }),
    other: genPageTheme({ colors: ["#4C566A", "#434C5E"], shape: shapes.wave }),
    app: genPageTheme({ colors: ["#5E81AC", "#81A1C1"], shape: shapes.wave }),
    apis: genPageTheme({ colors: ["#88C0D0", "#8FBCBB"], shape: shapes.wave2 }),
  },
  fontFamily: '"JetBrains Mono", "Fira Code", "SF Mono", Consolas, monospace',
  components: {
    ...createAlertStyles("light"),
    MuiButton: {
      styleOverrides: {
        root: { 
          borderRadius: 8, 
          textTransform: "none" as const, 
          fontWeight: 600,
          letterSpacing: "0.02em",
        },
        contained: {
          backgroundColor: "#5E81AC",
          "&:hover": { backgroundColor: "#81A1C1" },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: { 
          borderRadius: 12, 
          border: "1px solid #D8DEE9",
          boxShadow: "0 2px 8px rgba(46, 52, 64, 0.08)",
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        rounded: { borderRadius: 12 },
      },
    },
  },
});

const nordDark = createUnifiedTheme({
  palette: {
    ...palettes.dark,
    primary: { main: "#88C0D0" },
    secondary: { main: "#81A1C1" },
    error: { main: "#BF616A" },
    warning: { main: "#EBCB8B" },
    info: { main: "#8FBCBB" },
    success: { main: "#A3BE8C" },
    background: { default: "#2E3440", paper: "#3B4252" },
    navigation: {
      background: "#242933",
      indicator: "#88C0D0",
      color: "#D8DEE9",
      selectedColor: "#ECEFF4",
      navItem: { hoverBackground: "rgba(136, 192, 208, 0.1)" },
    },
  },
  defaultPageTheme: "home",
  pageTheme: {
    home: genPageTheme({ colors: ["#5E81AC", "#81A1C1"], shape: shapes.wave }),
    documentation: genPageTheme({ colors: ["#88C0D0", "#8FBCBB"], shape: shapes.wave2 }),
    tool: genPageTheme({ colors: ["#A3BE8C", "#8FBCBB"], shape: shapes.round }),
    service: genPageTheme({ colors: ["#5E81AC", "#81A1C1"], shape: shapes.wave }),
    website: genPageTheme({ colors: ["#B48EAD", "#A3BE8C"], shape: shapes.wave }),
    library: genPageTheme({ colors: ["#A3BE8C", "#8FBCBB"], shape: shapes.wave2 }),
    other: genPageTheme({ colors: ["#4C566A", "#434C5E"], shape: shapes.wave }),
    app: genPageTheme({ colors: ["#5E81AC", "#81A1C1"], shape: shapes.wave }),
    apis: genPageTheme({ colors: ["#88C0D0", "#8FBCBB"], shape: shapes.wave2 }),
  },
  fontFamily: '"JetBrains Mono", "Fira Code", "SF Mono", Consolas, monospace',
  components: {
    ...createAlertStyles("dark"),
    MuiButton: {
      styleOverrides: {
        root: { 
          borderRadius: 8, 
          textTransform: "none" as const, 
          fontWeight: 600,
          letterSpacing: "0.02em",
        },
        contained: {
          backgroundColor: "#88C0D0",
          color: "#2E3440",
          "&:hover": { backgroundColor: "#8FBCBB" },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: { 
          borderRadius: 12, 
          border: "1px solid #434C5E",
          boxShadow: "0 4px 16px rgba(0, 0, 0, 0.3)",
          backgroundImage: "none",
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: { backgroundImage: "none" },
        rounded: { borderRadius: 12 },
      },
    },
  },
});

// =============================================================================
// 5. DRACULA - Popular Dark Theme
// =============================================================================
const draculaLight = createUnifiedTheme({
  palette: {
    ...palettes.light,
    primary: { main: "#7C3AED" },
    secondary: { main: "#DB2777" },
    error: { main: "#DC2626" },
    warning: { main: "#F59E0B" },
    info: { main: "#0EA5E9" },
    success: { main: "#22C55E" },
    background: { default: "#F8F8F2", paper: "#FFFFFF" },
    navigation: {
      background: "#282A36",
      indicator: "#BD93F9",
      color: "#6272A4",
      selectedColor: "#F8F8F2",
      navItem: { hoverBackground: "rgba(189, 147, 249, 0.1)" },
    },
  },
  defaultPageTheme: "home",
  pageTheme: {
    home: genPageTheme({ colors: ["#BD93F9", "#FF79C6"], shape: shapes.wave }),
    documentation: genPageTheme({ colors: ["#8BE9FD", "#6272A4"], shape: shapes.wave2 }),
    tool: genPageTheme({ colors: ["#50FA7B", "#8BE9FD"], shape: shapes.round }),
    service: genPageTheme({ colors: ["#BD93F9", "#FF79C6"], shape: shapes.wave }),
    website: genPageTheme({ colors: ["#FF79C6", "#FFB86C"], shape: shapes.wave }),
    library: genPageTheme({ colors: ["#50FA7B", "#8BE9FD"], shape: shapes.wave2 }),
    other: genPageTheme({ colors: ["#6272A4", "#44475A"], shape: shapes.wave }),
    app: genPageTheme({ colors: ["#BD93F9", "#FF79C6"], shape: shapes.wave }),
    apis: genPageTheme({ colors: ["#8BE9FD", "#50FA7B"], shape: shapes.wave2 }),
  },
  fontFamily: '"Fira Code", "JetBrains Mono", Consolas, monospace',
  components: {
    ...createAlertStyles("light"),
    MuiButton: {
      styleOverrides: {
        root: { 
          borderRadius: 8, 
          textTransform: "none" as const, 
          fontWeight: 600,
        },
        contained: {
          background: "linear-gradient(135deg, #BD93F9 0%, #FF79C6 100%)",
          boxShadow: "0 4px 16px rgba(189, 147, 249, 0.35)",
          "&:hover": { boxShadow: "0 6px 24px rgba(189, 147, 249, 0.45)" },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: { 
          borderRadius: 12, 
          border: "1px solid #E0E0E0",
          boxShadow: "0 2px 8px rgba(40, 42, 54, 0.08)",
        },
      },
    },
  },
});

const draculaDark = createUnifiedTheme({
  palette: {
    ...palettes.dark,
    primary: { main: "#BD93F9" },
    secondary: { main: "#FF79C6" },
    error: { main: "#FF5555" },
    warning: { main: "#FFB86C" },
    info: { main: "#8BE9FD" },
    success: { main: "#50FA7B" },
    background: { default: "#282A36", paper: "#44475A" },
    navigation: {
      background: "#21222C",
      indicator: "#BD93F9",
      color: "#6272A4",
      selectedColor: "#F8F8F2",
      navItem: { hoverBackground: "rgba(189, 147, 249, 0.12)" },
    },
  },
  defaultPageTheme: "home",
  pageTheme: {
    home: genPageTheme({ colors: ["#BD93F9", "#FF79C6"], shape: shapes.wave }),
    documentation: genPageTheme({ colors: ["#8BE9FD", "#6272A4"], shape: shapes.wave2 }),
    tool: genPageTheme({ colors: ["#50FA7B", "#8BE9FD"], shape: shapes.round }),
    service: genPageTheme({ colors: ["#BD93F9", "#FF79C6"], shape: shapes.wave }),
    website: genPageTheme({ colors: ["#FF79C6", "#FFB86C"], shape: shapes.wave }),
    library: genPageTheme({ colors: ["#50FA7B", "#8BE9FD"], shape: shapes.wave2 }),
    other: genPageTheme({ colors: ["#6272A4", "#44475A"], shape: shapes.wave }),
    app: genPageTheme({ colors: ["#BD93F9", "#FF79C6"], shape: shapes.wave }),
    apis: genPageTheme({ colors: ["#8BE9FD", "#50FA7B"], shape: shapes.wave2 }),
  },
  fontFamily: '"Fira Code", "JetBrains Mono", Consolas, monospace',
  components: {
    ...createAlertStyles("dark"),
    MuiButton: {
      styleOverrides: {
        root: { 
          borderRadius: 8, 
          textTransform: "none" as const, 
          fontWeight: 600,
        },
        contained: {
          background: "linear-gradient(135deg, #BD93F9 0%, #FF79C6 100%)",
          boxShadow: "0 4px 16px rgba(189, 147, 249, 0.3)",
          "&:hover": { boxShadow: "0 6px 24px rgba(189, 147, 249, 0.4)" },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: { 
          borderRadius: 12, 
          border: "1px solid #6272A4",
          boxShadow: "0 4px 20px rgba(0, 0, 0, 0.4)",
          backgroundImage: "none",
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: { backgroundImage: "none" },
      },
    },
  },
});

// =============================================================================
// 6. CATPPUCCIN MOCHA - Soothing Pastel Theme
// =============================================================================
const catppuccinLight = createUnifiedTheme({
  palette: {
    ...palettes.light,
    primary: { main: "#8839EF" },
    secondary: { main: "#EA76CB" },
    error: { main: "#D20F39" },
    warning: { main: "#DF8E1D" },
    info: { main: "#04A5E5" },
    success: { main: "#40A02B" },
    background: { default: "#EFF1F5", paper: "#FFFFFF" },
    navigation: {
      background: "#1E1E2E",
      indicator: "#CBA6F7",
      color: "#A6ADC8",
      selectedColor: "#CDD6F4",
      navItem: { hoverBackground: "rgba(203, 166, 247, 0.1)" },
    },
  },
  defaultPageTheme: "home",
  pageTheme: {
    home: genPageTheme({ colors: ["#8839EF", "#EA76CB"], shape: shapes.wave }),
    documentation: genPageTheme({ colors: ["#04A5E5", "#209FB5"], shape: shapes.wave2 }),
    tool: genPageTheme({ colors: ["#40A02B", "#179299"], shape: shapes.round }),
    service: genPageTheme({ colors: ["#8839EF", "#7287FD"], shape: shapes.wave }),
    website: genPageTheme({ colors: ["#EA76CB", "#E64553"], shape: shapes.wave }),
    library: genPageTheme({ colors: ["#40A02B", "#179299"], shape: shapes.wave2 }),
    other: genPageTheme({ colors: ["#6C6F85", "#8C8FA1"], shape: shapes.wave }),
    app: genPageTheme({ colors: ["#8839EF", "#EA76CB"], shape: shapes.wave }),
    apis: genPageTheme({ colors: ["#04A5E5", "#209FB5"], shape: shapes.wave2 }),
  },
  fontFamily: '"Inter", -apple-system, BlinkMacSystemFont, sans-serif',
  components: {
    ...createAlertStyles("light"),
    MuiButton: {
      styleOverrides: {
        root: { borderRadius: 10, textTransform: "none" as const, fontWeight: 600 },
        contained: {
          background: "linear-gradient(135deg, #8839EF 0%, #EA76CB 100%)",
          boxShadow: "0 4px 16px rgba(136, 57, 239, 0.3)",
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: { borderRadius: 16, border: "1px solid #DCE0E8", boxShadow: "0 2px 8px rgba(0,0,0,0.05)" },
      },
    },
  },
});

const catppuccinDark = createUnifiedTheme({
  palette: {
    ...palettes.dark,
    primary: { main: "#CBA6F7" },
    secondary: { main: "#F5C2E7" },
    error: { main: "#F38BA8" },
    warning: { main: "#FAB387" },
    info: { main: "#89DCEB" },
    success: { main: "#A6E3A1" },
    background: { default: "#1E1E2E", paper: "#313244" },
    navigation: {
      background: "#11111B",
      indicator: "#CBA6F7",
      color: "#A6ADC8",
      selectedColor: "#CDD6F4",
      navItem: { hoverBackground: "rgba(203, 166, 247, 0.1)" },
    },
  },
  defaultPageTheme: "home",
  pageTheme: {
    home: genPageTheme({ colors: ["#CBA6F7", "#F5C2E7"], shape: shapes.wave }),
    documentation: genPageTheme({ colors: ["#89DCEB", "#94E2D5"], shape: shapes.wave2 }),
    tool: genPageTheme({ colors: ["#A6E3A1", "#94E2D5"], shape: shapes.round }),
    service: genPageTheme({ colors: ["#CBA6F7", "#B4BEFE"], shape: shapes.wave }),
    website: genPageTheme({ colors: ["#F5C2E7", "#F38BA8"], shape: shapes.wave }),
    library: genPageTheme({ colors: ["#A6E3A1", "#94E2D5"], shape: shapes.wave2 }),
    other: genPageTheme({ colors: ["#6C7086", "#7F849C"], shape: shapes.wave }),
    app: genPageTheme({ colors: ["#CBA6F7", "#F5C2E7"], shape: shapes.wave }),
    apis: genPageTheme({ colors: ["#89DCEB", "#94E2D5"], shape: shapes.wave2 }),
  },
  fontFamily: '"Inter", -apple-system, BlinkMacSystemFont, sans-serif',
  components: {
    ...createAlertStyles("dark"),
    MuiButton: {
      styleOverrides: {
        root: { borderRadius: 10, textTransform: "none" as const, fontWeight: 600 },
        contained: {
          background: "linear-gradient(135deg, #CBA6F7 0%, #F5C2E7 100%)",
          color: "#1E1E2E",
          boxShadow: "0 4px 16px rgba(203, 166, 247, 0.3)",
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: { 
          borderRadius: 16, 
          border: "1px solid #45475A", 
          boxShadow: "0 4px 16px rgba(0,0,0,0.3)",
          backgroundImage: "none",
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: { backgroundImage: "none" },
      },
    },
  },
});

// =============================================================================
// THEME PRESETS ARRAY
// =============================================================================
export const themePresets: ThemePreset[] = [
  {
    id: "backstage",
    name: "Backstage Default",
    description: "The classic Backstage developer portal theme",
    light: backstageDefaultLight,
    dark: backstageDefaultDark,
  },
  {
    id: "liquid-glass",
    name: "Liquid Glass",
    description: "Apple-inspired glassmorphism with translucent depth",
    light: liquidGlassLight,
    dark: liquidGlassDark,
  },
  {
    id: "github",
    name: "GitHub",
    description: "GitHub Primer design system",
    light: githubLight,
    dark: githubDark,
  },
  {
    id: "nord",
    name: "Nord",
    description: "Elegant Arctic color palette",
    light: nordLight,
    dark: nordDark,
  },
  {
    id: "dracula",
    name: "Dracula",
    description: "Popular dark theme with vibrant accents",
    light: draculaLight,
    dark: draculaDark,
  },
  {
    id: "catppuccin",
    name: "Catppuccin",
    description: "Soothing pastel theme for cozy coding",
    light: catppuccinLight,
    dark: catppuccinDark,
  },
];

export const getThemePreset = (id: string): ThemePreset => {
  return themePresets.find((t) => t.id === id) || themePresets[0];
};

export default themePresets;
