import React, { useEffect, useState, useMemo } from 'react';
import { SignInPage, SignInProviderConfig } from '@backstage/core-components';
import { githubAuthApiRef } from '@backstage/core-plugin-api';
import { makeStyles, Typography, Paper, Button } from '@material-ui/core';
import GitHubIcon from '@material-ui/icons/GitHub';
import PersonOutlineIcon from '@material-ui/icons/PersonOutline';

// Storage keys for theme preferences
const STORAGE_KEY_PRESET = 'cloud-sandbox-theme-preset';
const STORAGE_KEY_MODE = 'cloud-sandbox-theme-mode';

// Theme color palettes - must match ThemeProvider
const themeColorPalettes: Record<string, { light: any; dark: any }> = {
  backstage: {
    light: {
      primary: '#00796B',
      secondary: '#1976D2',
      background: '#F5F5F5',
      paper: '#FFFFFF',
      text: '#1F1F1F',
      accent: '#00BCD4',
      gradientStart: '#005B4B',
      gradientMid: '#00796B',
      gradientEnd: '#004D40',
    },
    dark: {
      primary: '#00695C',
      secondary: '#1565C0',
      background: '#1F1F1F',
      paper: '#2D2D2D',
      text: '#FFFFFF',
      accent: '#00838F',
      gradientStart: '#004D40',
      gradientMid: '#00695C',
      gradientEnd: '#002820',
    },
  },
  'liquid-glass': {
    light: {
      primary: '#007AFF',
      secondary: '#5856D6',
      background: '#F2F2F7',
      paper: 'rgba(255, 255, 255, 0.72)',
      text: '#1C1C1E',
      accent: '#5AC8FA',
      gradientStart: '#0f0c29',
      gradientMid: '#302b63',
      gradientEnd: '#24243e',
    },
    dark: {
      primary: '#0A84FF',
      secondary: '#5E5CE6',
      background: '#000000',
      paper: 'rgba(28, 28, 30, 0.72)',
      text: '#FFFFFF',
      accent: '#64D2FF',
      gradientStart: '#0f0c29',
      gradientMid: '#302b63',
      gradientEnd: '#24243e',
    },
  },
  github: {
    light: {
      primary: '#0969DA',
      secondary: '#8250DF',
      background: '#F6F8FA',
      paper: '#FFFFFF',
      text: '#24292F',
      accent: '#2DA44E',
      gradientStart: '#24292F',
      gradientMid: '#0D1117',
      gradientEnd: '#161B22',
    },
    dark: {
      primary: '#58A6FF',
      secondary: '#BC8CFF',
      background: '#0D1117',
      paper: '#161B22',
      text: '#F0F6FC',
      accent: '#3FB950',
      gradientStart: '#0D1117',
      gradientMid: '#161B22',
      gradientEnd: '#010409',
    },
  },
  nord: {
    light: {
      primary: '#5E81AC',
      secondary: '#81A1C1',
      background: '#ECEFF4',
      paper: '#FFFFFF',
      text: '#2E3440',
      accent: '#88C0D0',
      gradientStart: '#2E3440',
      gradientMid: '#3B4252',
      gradientEnd: '#434C5E',
    },
    dark: {
      primary: '#88C0D0',
      secondary: '#81A1C1',
      background: '#2E3440',
      paper: '#3B4252',
      text: '#ECEFF4',
      accent: '#8FBCBB',
      gradientStart: '#2E3440',
      gradientMid: '#3B4252',
      gradientEnd: '#242933',
    },
  },
  dracula: {
    light: {
      primary: '#7C3AED',
      secondary: '#DB2777',
      background: '#F8F8F2',
      paper: '#FFFFFF',
      text: '#282A36',
      accent: '#0EA5E9',
      gradientStart: '#282A36',
      gradientMid: '#44475A',
      gradientEnd: '#21222C',
    },
    dark: {
      primary: '#BD93F9',
      secondary: '#FF79C6',
      background: '#282A36',
      paper: '#44475A',
      text: '#F8F8F2',
      accent: '#8BE9FD',
      gradientStart: '#282A36',
      gradientMid: '#44475A',
      gradientEnd: '#21222C',
    },
  },
  catppuccin: {
    light: {
      primary: '#8839EF',
      secondary: '#EA76CB',
      background: '#EFF1F5',
      paper: '#FFFFFF',
      text: '#4C4F69',
      accent: '#04A5E5',
      gradientStart: '#1E1E2E',
      gradientMid: '#313244',
      gradientEnd: '#11111B',
    },
    dark: {
      primary: '#CBA6F7',
      secondary: '#F5C2E7',
      background: '#1E1E2E',
      paper: '#313244',
      text: '#CDD6F4',
      accent: '#89DCEB',
      gradientStart: '#1E1E2E',
      gradientMid: '#313244',
      gradientEnd: '#11111B',
    },
  },
};

// Helper to get theme colors synchronously
const getThemeColors = () => {
  const presetId = localStorage.getItem(STORAGE_KEY_PRESET) || 'github';
  const mode = localStorage.getItem(STORAGE_KEY_MODE) || 'system';

  let effectiveMode: 'light' | 'dark' = 'light';
  if (mode === 'system') {
    effectiveMode = window.matchMedia('(prefers-color-scheme: dark)').matches
      ? 'dark'
      : 'light';
  } else {
    effectiveMode = mode as 'light' | 'dark';
  }

  const palette = themeColorPalettes[presetId] || themeColorPalettes['github'];
  return { colors: palette[effectiveMode], presetId, effectiveMode };
};

const useStyles = makeStyles(() => ({
  '@keyframes float': {
    '0%, 100%': { transform: 'translateY(0px)' },
    '50%': { transform: 'translateY(-20px)' },
  },
  '@keyframes gradientShift': {
    '0%': { backgroundPosition: '0% 50%' },
    '50%': { backgroundPosition: '100% 50%' },
    '100%': { backgroundPosition: '0% 50%' },
  },
  '@keyframes fadeIn': {
    from: { opacity: 0, transform: 'translateY(20px)' },
    to: { opacity: 1, transform: 'translateY(0)' },
  },
  container: {
    minHeight: '100vh',
    display: 'flex',
    position: 'relative',
    overflow: 'hidden',
    transition: 'background 0.5s ease',
  },
  orb: {
    position: 'absolute',
    borderRadius: '50%',
    filter: 'blur(60px)',
    animation: ' 6s ease-in-out infinite',
    transition: 'background 0.5s ease',
  },
  orb1: {
    width: 400,
    height: 400,
    top: '-10%',
    left: '-5%',
    animationDelay: '0s',
  },
  orb2: {
    width: 300,
    height: 300,
    bottom: '10%',
    right: '-5%',
    animationDelay: '-2s',
  },
  orb3: {
    width: 200,
    height: 200,
    top: '60%',
    left: '10%',
    animationDelay: '-4s',
  },
  leftPanel: {
    flex: 1,
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
    padding: 64,
    zIndex: 1,
    '@media (max-width: 960px)': {
      display: 'none',
    },
  },
  brandContainer: {
    maxWidth: 500,
    animation: ' 0.6s ease-out',
  },
  logoMark: {
    width: 80,
    height: 80,
    borderRadius: 20,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 32,
    position: 'relative',
    transition: 'all 0.3s ease',
  },
  logoText: {
    color: '#fff',
    fontSize: '2rem',
    fontWeight: 800,
  },
  heroTitle: {
    fontSize: '3.5rem',
    fontWeight: 800,
    lineHeight: 1.1,
    marginBottom: 24,
    WebkitBackgroundClip: 'text',
    WebkitTextFillColor: 'transparent',
    backgroundClip: 'text',
    transition: 'background 0.3s ease',
  },
  heroSubtitle: {
    fontSize: '1.25rem',
    lineHeight: 1.6,
    marginBottom: 48,
    transition: 'color 0.3s ease',
  },
  featureGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(2, 1fr)',
    gap: 24,
  },
  featureItem: {
    display: 'flex',
    alignItems: 'flex-start',
    gap: 16,
  },
  featureIcon: {
    width: 40,
    height: 40,
    borderRadius: 10,
    backdropFilter: 'blur(10px)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontSize: '1.2rem',
    flexShrink: 0,
    transition: 'all 0.3s ease',
  },
  featureText: {
    '& h4': {
      fontSize: '1rem',
      fontWeight: 600,
      marginBottom: 4,
      transition: 'color 0.3s ease',
    },
    '& p': {
      fontSize: '0.875rem',
      margin: 0,
      transition: 'color 0.3s ease',
    },
  },
  rightPanel: {
    width: 520,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 32,
    zIndex: 1,
    '@media (max-width: 960px)': {
      width: '100%',
    },
  },
  loginCard: {
    width: '100%',
    maxWidth: 420,
    backdropFilter: 'blur(20px)',
    borderRadius: 24,
    padding: 40,
    animation: ' 0.6s ease-out 0.2s both',
    transition: 'all 0.3s ease',
  },
  loginHeader: {
    textAlign: 'center',
    marginBottom: 32,
  },
  loginTitle: {
    fontSize: '1.75rem',
    fontWeight: 700,
    marginBottom: 8,
    transition: 'color 0.3s ease',
  },
  loginSubtitle: {
    fontSize: '0.95rem',
    transition: 'color 0.3s ease',
  },
  divider: {
    display: 'flex',
    alignItems: 'center',
    margin: '24px 0',
  },
  dividerLine: {
    flex: 1,
    height: 1,
    transition: 'background 0.3s ease',
  },
  dividerText: {
    padding: '0 16px',
    fontSize: '0.8rem',
    textTransform: 'uppercase',
    letterSpacing: 1,
    transition: 'color 0.3s ease',
  },
  githubButton: {
    width: '100%',
    padding: 14,
    fontSize: '1rem',
    fontWeight: 600,
    borderRadius: 12,
    textTransform: 'none',
    marginBottom: 16,
    transition: 'all 0.3s ease',
    '&:hover': {
      transform: 'translateY(-2px)',
    },
  },
  guestButton: {
    width: '100%',
    padding: 14,
    fontSize: '1rem',
    fontWeight: 500,
    borderRadius: 12,
    textTransform: 'none',
    transition: 'all 0.3s ease',
    '&:hover': {
      transform: 'translateY(-1px)',
    },
  },
  accessNote: {
    marginTop: 24,
    padding: 16,
    borderRadius: 12,
    transition: 'all 0.3s ease',
  },
  accessNoteTitle: {
    fontSize: '0.8rem',
    fontWeight: 600,
    marginBottom: 4,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    transition: 'color 0.3s ease',
  },
  accessNoteText: {
    fontSize: '0.85rem',
    lineHeight: 1.5,
    margin: 0,
    transition: 'color 0.3s ease',
  },
  footer: {
    position: 'absolute',
    bottom: 24,
    left: '50%',
    transform: 'translateX(-50%)',
    fontSize: '0.8rem',
    zIndex: 1,
    transition: 'color 0.3s ease',
  },
  hiddenSignIn: {
    display: 'none',
  },
}));

const githubProvider: SignInProviderConfig = {
  id: 'github-auth-provider',
  title: 'GitHub',
  message: 'Sign in with GitHub',
  apiRef: githubAuthApiRef,
};

export const CustomSignInPage = (props: any) => {
  const classes = useStyles();
  const signInRef = React.useRef<HTMLDivElement>(null);

  // Get initial theme colors
  const [themeState, setThemeState] = useState(() => getThemeColors());

  // Listen for theme changes from inside the app
  useEffect(() => {
    const handleThemeChange = () => {
      setThemeState(getThemeColors());
    };

    // Listen for custom theme change events
    window.addEventListener('themeChange', handleThemeChange);
    // Also listen for storage changes (in case changed in another tab)
    window.addEventListener('storage', handleThemeChange);
    // Listen for system theme changes
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    mediaQuery.addEventListener('change', handleThemeChange);

    return () => {
      window.removeEventListener('themeChange', handleThemeChange);
      window.removeEventListener('storage', handleThemeChange);
      mediaQuery.removeEventListener('change', handleThemeChange);
    };
  }, []);

  const { colors, effectiveMode } = themeState;
  const isDark = effectiveMode === 'dark';

  // Dynamic styles based on theme
  const dynamicStyles = useMemo(
    () => ({
      container: {
        background: `linear-gradient(-45deg, ${colors.gradientStart}, ${colors.gradientMid}, ${colors.gradientEnd}, ${colors.gradientStart})`,
        backgroundSize: '400% 400%',
        animation: 'gradientShift 15s ease infinite',
      },
      orb1: {
        background: `radial-gradient(circle, ${colors.primary}66 0%, transparent 70%)`,
      },
      orb2: {
        background: `radial-gradient(circle, ${colors.secondary}4D 0%, transparent 70%)`,
      },
      orb3: {
        background: `radial-gradient(circle, ${colors.accent}4D 0%, transparent 70%)`,
      },
      logoMark: {
        background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.secondary} 50%, ${colors.accent} 100%)`,
        boxShadow: `0 20px 40px ${colors.primary}66`,
      },
      heroTitle: {
        background: `linear-gradient(135deg, #ffffff 0%, ${colors.accent} 100%)`,
      },
      heroSubtitle: {
        color: 'rgba(255, 255, 255, 0.7)',
      },
      featureIcon: {
        background: 'rgba(255, 255, 255, 0.1)',
        color: colors.accent,
      },
      featureTitle: {
        color: '#ffffff',
      },
      featureDesc: {
        color: 'rgba(255, 255, 255, 0.5)',
      },
      loginCard: {
        background: isDark
          ? 'rgba(255, 255, 255, 0.03)'
          : 'rgba(255, 255, 255, 0.08)',
        border: '1px solid rgba(255, 255, 255, 0.1)',
        boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.5)',
      },
      loginTitle: {
        color: '#ffffff',
      },
      loginSubtitle: {
        color: 'rgba(255, 255, 255, 0.5)',
      },
      dividerLine: {
        background: 'rgba(255, 255, 255, 0.1)',
      },
      dividerText: {
        color: 'rgba(255, 255, 255, 0.4)',
      },
      githubButton: {
        background: '#ffffff',
        color: colors.gradientStart,
        boxShadow: '0 4px 20px rgba(255, 255, 255, 0.15)',
      },
      guestButton: {
        background: 'transparent',
        color: 'rgba(255, 255, 255, 0.8)',
        border: '1px solid rgba(255, 255, 255, 0.2)',
      },
      accessNote: {
        background: `${colors.primary}1A`,
        border: `1px solid ${colors.primary}33`,
      },
      accessNoteTitle: {
        color: colors.accent,
      },
      accessNoteText: {
        color: 'rgba(255, 255, 255, 0.6)',
      },
      footer: {
        color: 'rgba(255, 255, 255, 0.3)',
      },
    }),
    [colors, isDark],
  );

  const handleGitHubClick = () => {
    const githubBtn = signInRef.current?.querySelector('button');
    if (githubBtn) githubBtn.click();
  };

  const handleGuestClick = () => {
    const buttons = signInRef.current?.querySelectorAll('button');
    if (buttons && buttons.length > 1) buttons[1].click();
  };

  return (
    <div className={classes.container} style={dynamicStyles.container}>
      {/* Animated background orbs */}
      <div
        className={`${classes.orb} ${classes.orb1}`}
        style={dynamicStyles.orb1}
      />
      <div
        className={`${classes.orb} ${classes.orb2}`}
        style={dynamicStyles.orb2}
      />
      <div
        className={`${classes.orb} ${classes.orb3}`}
        style={dynamicStyles.orb3}
      />

      {/* Left Panel - Branding */}
      <div className={classes.leftPanel}>
        <div className={classes.brandContainer}>
          <div className={classes.logoMark} style={dynamicStyles.logoMark}>
            <span className={classes.logoText}>CS</span>
          </div>

          <Typography
            className={classes.heroTitle}
            style={{
              ...dynamicStyles.heroTitle,
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
            }}
          >
            Cloud Sandbox
            <br />
            Developer Portal
          </Typography>

          <Typography
            className={classes.heroSubtitle}
            style={dynamicStyles.heroSubtitle}
          >
            Your unified platform for discovering services, APIs, documentation,
            and scaffolding new projects.
          </Typography>

          <div className={classes.featureGrid}>
            <div className={classes.featureItem}>
              <div
                className={classes.featureIcon}
                style={dynamicStyles.featureIcon}
              >
                &#128230;
              </div>
              <div className={classes.featureText}>
                <h4 style={dynamicStyles.featureTitle}>Software Catalog</h4>
                <p style={dynamicStyles.featureDesc}>
                  Discover and manage services
                </p>
              </div>
            </div>
            <div className={classes.featureItem}>
              <div
                className={classes.featureIcon}
                style={dynamicStyles.featureIcon}
              >
                &#128196;
              </div>
              <div className={classes.featureText}>
                <h4 style={dynamicStyles.featureTitle}>TechDocs</h4>
                <p style={dynamicStyles.featureDesc}>
                  Centralized documentation
                </p>
              </div>
            </div>
            <div className={classes.featureItem}>
              <div
                className={classes.featureIcon}
                style={dynamicStyles.featureIcon}
              >
                &#9881;
              </div>
              <div className={classes.featureText}>
                <h4 style={dynamicStyles.featureTitle}>Templates</h4>
                <p style={dynamicStyles.featureDesc}>Scaffold new projects</p>
              </div>
            </div>
            <div className={classes.featureItem}>
              <div
                className={classes.featureIcon}
                style={dynamicStyles.featureIcon}
              >
                &#128279;
              </div>
              <div className={classes.featureText}>
                <h4 style={dynamicStyles.featureTitle}>API Explorer</h4>
                <p style={dynamicStyles.featureDesc}>
                  Browse API specifications
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Right Panel - Login */}
      <div className={classes.rightPanel}>
        <Paper
          className={classes.loginCard}
          style={dynamicStyles.loginCard}
          elevation={0}
        >
          <div className={classes.loginHeader}>
            <Typography
              className={classes.loginTitle}
              style={dynamicStyles.loginTitle}
            >
              Welcome back
            </Typography>
            <Typography
              className={classes.loginSubtitle}
              style={dynamicStyles.loginSubtitle}
            >
              Sign in to access the developer portal
            </Typography>
          </div>

          <Button
            className={classes.githubButton}
            style={dynamicStyles.githubButton}
            startIcon={<GitHubIcon />}
            onClick={handleGitHubClick}
            variant="contained"
            disableElevation
          >
            Continue with GitHub
          </Button>

          <div className={classes.divider}>
            <div
              className={classes.dividerLine}
              style={dynamicStyles.dividerLine}
            />
            <span
              className={classes.dividerText}
              style={dynamicStyles.dividerText}
            >
              or
            </span>
            <div
              className={classes.dividerLine}
              style={dynamicStyles.dividerLine}
            />
          </div>

          <Button
            className={classes.guestButton}
            style={dynamicStyles.guestButton}
            startIcon={<PersonOutlineIcon />}
            onClick={handleGuestClick}
            variant="outlined"
          >
            Continue as Guest
          </Button>

          <div className={classes.accessNote} style={dynamicStyles.accessNote}>
            <div
              className={classes.accessNoteTitle}
              style={dynamicStyles.accessNoteTitle}
            >
              Access Levels
            </div>
            <p
              className={classes.accessNoteText}
              style={dynamicStyles.accessNoteText}
            >
              <strong>GitHub:</strong> Full access to all features
              <br />
              <strong>Guest:</strong> Read-only browsing
            </p>
          </div>

          {/* Hidden SignInPage for actual auth handling */}
          <div ref={signInRef} className={classes.hiddenSignIn}>
            <SignInPage
              {...props}
              providers={[githubProvider, 'guest']}
              title=""
              align="center"
            />
          </div>
        </Paper>
      </div>

      <Typography className={classes.footer} style={dynamicStyles.footer}>
        Powered by Backstage
      </Typography>
    </div>
  );
};

export default CustomSignInPage;
