import { makeStyles, Snackbar } from '@material-ui/core';
import { Alert, AlertProps } from '@material-ui/lab';
import { alertApiRef, useApi } from '@backstage/core-plugin-api';
import useObservable from 'react-use/lib/useObservable';

const useStyles = makeStyles(theme => ({
  snackbar: {
    // Position at top center for better visibility
    top: theme.spacing(2),
  },
  alert: {
    // Make alerts more prominent
    boxShadow: theme.shadows[8],
    borderRadius: theme.shape.borderRadius,
    fontWeight: 500,
    fontSize: '0.95rem',
    minWidth: 300,
    '& .MuiAlert-icon': {
      fontSize: '1.5rem',
    },
    '& .MuiAlert-message': {
      padding: theme.spacing(1, 0),
    },
    '& .MuiAlert-action': {
      paddingLeft: theme.spacing(2),
    },
  },
  // Success - vibrant green
  successAlert: {
    backgroundColor: '#2e7d32',
    color: '#ffffff',
    '& .MuiAlert-icon': {
      color: '#ffffff',
    },
  },
  // Error - strong red
  errorAlert: {
    backgroundColor: '#d32f2f',
    color: '#ffffff',
    '& .MuiAlert-icon': {
      color: '#ffffff',
    },
  },
  // Warning - bold orange
  warningAlert: {
    backgroundColor: '#ed6c02',
    color: '#ffffff',
    '& .MuiAlert-icon': {
      color: '#ffffff',
    },
  },
  // Info - solid blue
  infoAlert: {
    backgroundColor: '#0288d1',
    color: '#ffffff',
    '& .MuiAlert-icon': {
      color: '#ffffff',
    },
  },
}));

/**
 * Custom AlertDisplay component with more visible, tangible toast notifications.
 * Uses solid colors instead of pale/muted tones for better visibility.
 */
export const CustomAlertDisplay = () => {
  const classes = useStyles();
  const alertApi = useApi(alertApiRef);
  const alert = useObservable(alertApi.alert$());

  if (!alert) {
    return null;
  }

  const { message, severity } = alert;

  const getSeverityClass = (sev: AlertProps['severity']) => {
    switch (sev) {
      case 'success':
        return classes.successAlert;
      case 'error':
        return classes.errorAlert;
      case 'warning':
        return classes.warningAlert;
      case 'info':
      default:
        return classes.infoAlert;
    }
  };

  const handleClose = () => {
    alertApi.post({ message: '', severity: 'info' });
  };

  return (
    <Snackbar
      open
      autoHideDuration={6000}
      anchorOrigin={{ vertical: 'top', horizontal: 'center' }}
      className={classes.snackbar}
      onClose={handleClose}
    >
      <Alert
        severity={severity || 'info'}
        className={`${classes.alert} ${getSeverityClass(severity)}`}
        onClose={handleClose}
        variant="filled"
        elevation={6}
      >
        {message}
      </Alert>
    </Snackbar>
  );
};

export default CustomAlertDisplay;
