import React, { useEffect, useState, useMemo } from 'react';
import { makeStyles } from '@material-ui/core';
import { STORAGE_KEY_PRESET, STORAGE_KEY_MODE } from '../ThemeProvider';

// Theme color palettes - simplified version for loading screen
const themeColorPalettes: Record<string, { light: any; dark: any }> = {
  backstage: {
    light: { primary: '#00796B', secondary: '#1976D2', accent: '#00BCD4', bg: '#F5F5F5' },
    dark: { primary: '#00695C', secondary: '#1565C0', accent: '#00838F', bg: '#1F1F1F' },
  },
  'liquid-glass': {
    light: { primary: '#007AFF', secondary: '#5856D6', accent: '#5AC8FA', bg: '#F2F2F7' },
    dark: { primary: '#0A84FF', secondary: '#5E5CE6', accent: '#64D2FF', bg: '#000000' },
  },
  github: {
    light: { primary: '#0969DA', secondary: '#8250DF', accent: '#2DA44E', bg: '#F6F8FA' },
    dark: { primary: '#58A6FF', secondary: '#BC8CFF', accent: '#3FB950', bg: '#0D1117' },
  },
  nord: {
    light: { primary: '#5E81AC', secondary: '#81A1C1', accent: '#88C0D0', bg: '#ECEFF4' },
    dark: { primary: '#88C0D0', secondary: '#81A1C1', accent: '#8FBCBB', bg: '#2E3440' },
  },
  dracula: {
    light: { primary: '#7C3AED', secondary: '#DB2777', accent: '#0EA5E9', bg: '#F8F8F2' },
    dark: { primary: '#BD93F9', secondary: '#FF79C6', accent: '#8BE9FD', bg: '#282A36' },
  },
  catppuccin: {
    light: { primary: '#8839EF', secondary: '#EA76CB', accent: '#04A5E5', bg: '#EFF1F5' },
    dark: { primary: '#CBA6F7', secondary: '#F5C2E7', accent: '#89DCEB', bg: '#1E1E2E' },
  },
};

const getThemeColors = () => {
  const presetId = typeof window !== 'undefined' ? localStorage.getItem(STORAGE_KEY_PRESET) || 'backstage' : 'backstage';
  const mode = typeof window !== 'undefined' ? localStorage.getItem(STORAGE_KEY_MODE) || 'system' : 'system';
  
  let effectiveMode: 'light' | 'dark' = 'light';
  if (mode === 'system' && typeof window !== 'undefined') {
    effectiveMode = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  } else if (mode === 'dark' || mode === 'light') {
    effectiveMode = mode;
  }
  
  const palette = themeColorPalettes[presetId] || themeColorPalettes['backstage'];
  return { colors: palette[effectiveMode], effectiveMode };
};

const useStyles = makeStyles({
  '@keyframes spin': {
    '0%': { transform: 'rotate(0deg)' },
    '100%': { transform: 'rotate(360deg)' },
  },
  '@keyframes pulse': {
    '0%, 100%': { opacity: 0.6, transform: 'scale(1)' },
    '50%': { opacity: 1, transform: 'scale(1.05)' },
  },
  '@keyframes slideUp': {
    from: { opacity: 0, transform: 'translateY(10px)' },
    to: { opacity: 1, transform: 'translateY(0)' },
  },
  '@keyframes progressAnim': {
    '0%': { width: '0%', marginLeft: '0%' },
    '50%': { width: '60%', marginLeft: '20%' },
    '100%': { width: '0%', marginLeft: '100%' },
  },
  container: {
    position: 'fixed',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 9999,
    transition: 'opacity 0.4s ease-out, background 0.3s ease',
  },
  containerHidden: {
    opacity: 0,
    pointerEvents: 'none' as const,
  },
  content: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    gap: 24,
  },
  logoContainer: {
    position: 'relative',
    animation: ' 2s ease-in-out infinite',
  },
  logoMark: {
    width: 80,
    height: 80,
    borderRadius: 20,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    transition: 'all 0.3s ease',
  },
  logoText: {
    color: '#fff',
    fontSize: '2rem',
    fontWeight: 800,
    letterSpacing: '-1px',
  },
  spinnerRing: {
    position: 'absolute',
    top: -8,
    left: -8,
    right: -8,
    bottom: -8,
    border: '3px solid transparent',
    borderRadius: '50%',
    animation: ' 1s linear infinite',
    transition: 'border-color 0.3s ease',
  },
  title: {
    fontSize: '1.5rem',
    fontWeight: 600,
    letterSpacing: '-0.5px',
    margin: 0,
    animation: ' 0.5s ease-out 0.1s both',
    transition: 'color 0.3s ease',
  },
  subtitle: {
    fontSize: '0.95rem',
    fontWeight: 400,
    margin: 0,
    animation: ' 0.5s ease-out 0.2s both',
    transition: 'color 0.3s ease',
  },
  progressContainer: {
    width: 200,
    height: 3,
    borderRadius: 2,
    overflow: 'hidden',
    marginTop: 8,
    animation: ' 0.5s ease-out 0.3s both',
    transition: 'background 0.3s ease',
  },
  progressBar: {
    height: '100%',
    borderRadius: 2,
    animation: ' 1.5s ease-in-out infinite',
    transition: 'background 0.3s ease',
  },
});

interface LoadingScreenProps {
  message?: string;
  isLoading?: boolean;
}

export const LoadingScreen: React.FC<LoadingScreenProps> = ({ 
  message = 'Loading developer portal...',
  isLoading = true,
}) => {
  const classes = useStyles();
  const [shouldRender, setShouldRender] = useState(isLoading);
  const { colors, effectiveMode } = useMemo(() => getThemeColors(), []);
  const isDark = effectiveMode === 'dark';

  useEffect(() => {
    if (!isLoading) {
      const timer = setTimeout(() => setShouldRender(false), 400);
      return () => clearTimeout(timer);
    }
    setShouldRender(true);
    return undefined;
  }, [isLoading]);

  const dynamicStyles = useMemo(() => ({
    container: {
      background: isDark 
        ? `linear-gradient(135deg, ${colors.bg} 0%, #16213e 50%, #0f3460 100%)`
        : `linear-gradient(135deg, ${colors.bg} 0%, #e8eef5 50%, #d4e0ed 100%)`,
    },
    logoMark: {
      background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.secondary} 50%, ${colors.accent} 100%)`,
      boxShadow: `0 20px 40px ${colors.primary}66`,
    },
    spinnerRing: {
      borderTopColor: colors.primary,
    },
    title: {
      color: isDark ? '#ffffff' : colors.bg === '#F5F5F5' ? '#1F1F1F' : '#1a1a1a',
    },
    subtitle: {
      color: isDark ? 'rgba(255, 255, 255, 0.6)' : 'rgba(0, 0, 0, 0.5)',
    },
    progressContainer: {
      backgroundColor: isDark ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)',
    },
    progressBar: {
      background: `linear-gradient(90deg, ${colors.primary}, ${colors.secondary}, ${colors.accent})`,
    },
  }), [colors, isDark]);

  if (!shouldRender) return null;

  return (
    <div 
      className={`${classes.container} ${!isLoading ? classes.containerHidden : ''}`}
      style={dynamicStyles.container}
    >
      <div className={classes.content}>
        <div className={classes.logoContainer}>
          <div className={classes.logoMark} style={dynamicStyles.logoMark}>
            <span className={classes.logoText}>CS</span>
          </div>
          <div className={classes.spinnerRing} style={dynamicStyles.spinnerRing} />
        </div>
        <h1 className={classes.title} style={dynamicStyles.title}>Cloud Sandbox</h1>
        <p className={classes.subtitle} style={dynamicStyles.subtitle}>{message}</p>
        <div className={classes.progressContainer} style={dynamicStyles.progressContainer}>
          <div className={classes.progressBar} style={dynamicStyles.progressBar} />
        </div>
      </div>
    </div>
  );
};

export default LoadingScreen;
