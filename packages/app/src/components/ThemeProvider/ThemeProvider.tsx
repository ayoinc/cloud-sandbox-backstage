import React, { createContext, useContext, useState, useEffect, useMemo, useCallback } from "react";
import { UnifiedThemeProvider } from "@backstage/theme";
import CssBaseline from "@material-ui/core/CssBaseline";
import { themePresets, getThemePreset, ThemePreset } from "../../themes";

type ThemeMode = "light" | "dark" | "system";

interface ThemeContextValue {
  themePresetId: string;
  themeMode: ThemeMode;
  effectiveMode: "light" | "dark";
  setThemePresetId: (id: string) => void;
  setThemeMode: (mode: ThemeMode) => void;
  availablePresets: ThemePreset[];
  isLoading: boolean;
  themeColors: {
    primary: string;
    secondary: string;
    background: string;
    paper: string;
    text: string;
    accent: string;
  };
}

const ThemeContext = createContext<ThemeContextValue | undefined>(undefined);

export const useThemeContext = () => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error("useThemeContext must be used within ThemeProvider");
  }
  return context;
};

export const useThemeContextSafe = () => {
  return useContext(ThemeContext);
};

export const STORAGE_KEY_PRESET = "cloud-sandbox-theme-preset";
export const STORAGE_KEY_MODE = "cloud-sandbox-theme-mode";

const getInitialThemePreset = (): string => {
  if (typeof window !== "undefined") {
    return localStorage.getItem(STORAGE_KEY_PRESET) || "backstage";
  }
  return "backstage";
};

const getInitialThemeMode = (): ThemeMode => {
  if (typeof window !== "undefined") {
    return (localStorage.getItem(STORAGE_KEY_MODE) as ThemeMode) || "system";
  }
  return "system";
};

const getSystemPrefersDark = (): boolean => {
  if (typeof window !== "undefined") {
    return window.matchMedia("(prefers-color-scheme: dark)").matches;
  }
  return false;
};

// Color palettes for each theme preset (for non-MUI components like login page)
const themeColorPalettes: Record<string, { light: ThemeContextValue["themeColors"]; dark: ThemeContextValue["themeColors"] }> = {
  backstage: {
    light: {
      primary: "#00796B",
      secondary: "#1976D2",
      background: "#F5F5F5",
      paper: "#FFFFFF",
      text: "#1F1F1F",
      accent: "#00BCD4",
    },
    dark: {
      primary: "#00695C",
      secondary: "#1565C0",
      background: "#1F1F1F",
      paper: "#2D2D2D",
      text: "#FFFFFF",
      accent: "#00838F",
    },
  },
  "liquid-glass": {
    light: {
      primary: "#007AFF",
      secondary: "#5856D6",
      background: "#F2F2F7",
      paper: "rgba(255, 255, 255, 0.72)",
      text: "#1C1C1E",
      accent: "#5AC8FA",
    },
    dark: {
      primary: "#0A84FF",
      secondary: "#5E5CE6",
      background: "#000000",
      paper: "rgba(28, 28, 30, 0.72)",
      text: "#FFFFFF",
      accent: "#64D2FF",
    },
  },
  github: {
    light: {
      primary: "#0969DA",
      secondary: "#8250DF",
      background: "#F6F8FA",
      paper: "#FFFFFF",
      text: "#24292F",
      accent: "#2DA44E",
    },
    dark: {
      primary: "#58A6FF",
      secondary: "#BC8CFF",
      background: "#0D1117",
      paper: "#161B22",
      text: "#F0F6FC",
      accent: "#3FB950",
    },
  },
  nord: {
    light: {
      primary: "#5E81AC",
      secondary: "#81A1C1",
      background: "#ECEFF4",
      paper: "#FFFFFF",
      text: "#2E3440",
      accent: "#88C0D0",
    },
    dark: {
      primary: "#88C0D0",
      secondary: "#81A1C1",
      background: "#2E3440",
      paper: "#3B4252",
      text: "#ECEFF4",
      accent: "#8FBCBB",
    },
  },
  dracula: {
    light: {
      primary: "#7C3AED",
      secondary: "#DB2777",
      background: "#F8F8F2",
      paper: "#FFFFFF",
      text: "#282A36",
      accent: "#0EA5E9",
    },
    dark: {
      primary: "#BD93F9",
      secondary: "#FF79C6",
      background: "#282A36",
      paper: "#44475A",
      text: "#F8F8F2",
      accent: "#8BE9FD",
    },
  },
  catppuccin: {
    light: {
      primary: "#8839EF",
      secondary: "#EA76CB",
      background: "#EFF1F5",
      paper: "#FFFFFF",
      text: "#4C4F69",
      accent: "#04A5E5",
    },
    dark: {
      primary: "#CBA6F7",
      secondary: "#F5C2E7",
      background: "#1E1E2E",
      paper: "#313244",
      text: "#CDD6F4",
      accent: "#89DCEB",
    },
  },
};

interface ThemeProviderProps {
  children: React.ReactNode;
}

export const ThemeProvider: React.FC<ThemeProviderProps> = ({ children }) => {
  const [themePresetId, setThemePresetIdState] = useState<string>(getInitialThemePreset);
  const [themeMode, setThemeModeState] = useState<ThemeMode>(getInitialThemeMode);
  const [systemPrefersDark, setSystemPrefersDark] = useState(getSystemPrefersDark);
  const [isLoading, setIsLoading] = useState(true);
  const [isHydrated, setIsHydrated] = useState(false);

  useEffect(() => {
    const mediaQuery = window.matchMedia("(prefers-color-scheme: dark)");
    const handler = (e: MediaQueryListEvent) => setSystemPrefersDark(e.matches);
    mediaQuery.addEventListener("change", handler);
    return () => mediaQuery.removeEventListener("change", handler);
  }, []);

  useEffect(() => {
    const fetchBranding = async () => {
      try {
        const response = await fetch("/api/branding-settings");
        if (response.ok) {
          const data = await response.json();
          if (data.themePreset) {
            if (!localStorage.getItem(STORAGE_KEY_PRESET)) {
              setThemePresetIdState(data.themePreset);
            }
          }
        }
      } catch {
        // Ignore errors, use defaults
      } finally {
        setIsHydrated(true);
        setTimeout(() => setIsLoading(false), 150);
      }
    };
    fetchBranding();
  }, []);

  const effectiveMode = useMemo(() => {
    if (themeMode === "system") {
      return systemPrefersDark ? "dark" : "light";
    }
    return themeMode;
  }, [themeMode, systemPrefersDark]);

  const setThemePresetId = useCallback((id: string) => {
    setThemePresetIdState(id);
    localStorage.setItem(STORAGE_KEY_PRESET, id);
    window.dispatchEvent(new CustomEvent("themeChange", { detail: { preset: id } }));
  }, []);

  const setThemeMode = useCallback((mode: ThemeMode) => {
    setThemeModeState(mode);
    localStorage.setItem(STORAGE_KEY_MODE, mode);
    window.dispatchEvent(new CustomEvent("themeChange", { detail: { mode } }));
  }, []);

  const currentPreset = useMemo(() => getThemePreset(themePresetId), [themePresetId]);
  const currentTheme = useMemo(
    () => (effectiveMode === "dark" ? currentPreset.dark : currentPreset.light),
    [currentPreset, effectiveMode]
  );

  const themeColors = useMemo(() => {
    const palette = themeColorPalettes[themePresetId] || themeColorPalettes["backstage"];
    return effectiveMode === "dark" ? palette.dark : palette.light;
  }, [themePresetId, effectiveMode]);

  useEffect(() => {
    if (!isHydrated) return;
    
    const root = document.documentElement;
    root.style.setProperty("--theme-primary", themeColors.primary);
    root.style.setProperty("--theme-secondary", themeColors.secondary);
    root.style.setProperty("--theme-background", themeColors.background);
    root.style.setProperty("--theme-paper", themeColors.paper);
    root.style.setProperty("--theme-text", themeColors.text);
    root.style.setProperty("--theme-accent", themeColors.accent);
    root.style.setProperty("--theme-mode", effectiveMode);
    root.setAttribute("data-theme", themePresetId);
    root.setAttribute("data-theme-mode", effectiveMode);
  }, [themeColors, themePresetId, effectiveMode, isHydrated]);

  const contextValue = useMemo<ThemeContextValue>(
    () => ({
      themePresetId,
      themeMode,
      effectiveMode,
      setThemePresetId,
      setThemeMode,
      availablePresets: themePresets,
      isLoading,
      themeColors,
    }),
    [themePresetId, themeMode, effectiveMode, setThemePresetId, setThemeMode, isLoading, themeColors]
  );

  return (
    <ThemeContext.Provider value={contextValue}>
      <UnifiedThemeProvider theme={currentTheme}>
        <CssBaseline />
        {children}
      </UnifiedThemeProvider>
    </ThemeContext.Provider>
  );
};

export default ThemeProvider;
