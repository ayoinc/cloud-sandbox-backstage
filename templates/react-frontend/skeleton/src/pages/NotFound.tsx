import type { FC } from "react";
{%- if values.ui_framework == 'mui' %}
import { Container, Typography, Box, Button } from "@mui/material";
import { Link as RouterLink } from "react-router-dom";
{%- endif %}

export const NotFound: FC = () => {
  return (
{%- if values.ui_framework == 'mui' %}
    <Container maxWidth="lg" sx={{ py: 4, textAlign: "center" }}>
      <Box>
        <Typography variant="h1" component="h1" gutterBottom>
          404
        </Typography>
        <Typography variant="h5" color="text.secondary" paragraph>
          Page not found
        </Typography>
        <Button component={RouterLink} to="/" variant="contained">
          Go Home
        </Button>
      </Box>
    </Container>
{%- else %}
    <main className="not-found">
      <h1>404</h1>
      <p>Page not found</p>
      <a href="/">Go Home</a>
    </main>
{%- endif %}
  );
};
