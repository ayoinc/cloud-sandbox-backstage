import { AppBar, Box, Container, Toolbar, Typography } from "@mui/material";
import type { ReactNode } from "react";

export interface LayoutProps {
  /** Application name shown in the header. */
  title: string;
  /** Links shown next to the title. */
  nav?: ReactNode;
  children: ReactNode;
}

export function Layout({ title, nav, children }: LayoutProps) {
  return (
    <>
      <AppBar position="static">
        <Toolbar sx={{ gap: 3 }}>
          <Typography variant="h6" component="h1">
            {title}
          </Typography>
          {nav ? (
            <Box
              component="nav"
              aria-label="Main"
              sx={{
                display: "flex",
                gap: 2,
                "& a": { color: "inherit", textDecoration: "none" },
                // React Router marks the link of the current page with the class "active".
                "& a.active": { textDecoration: "underline" },
              }}
            >
              {nav}
            </Box>
          ) : null}
        </Toolbar>
      </AppBar>
      <Container component="main" maxWidth="md" sx={{ py: 4 }}>
        {children}
      </Container>
    </>
  );
}
