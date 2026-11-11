import { createTheme } from "@mui/material";

/** Material UI theme of the application: palette, shape and typography overrides go here. */
export const theme = createTheme({
  palette: {
    primary: { main: "#1565c0" },
    background: { default: "#f6f8fa" },
  },
  shape: { borderRadius: 8 },
});
