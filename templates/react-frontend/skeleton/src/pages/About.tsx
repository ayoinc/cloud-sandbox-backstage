import type { FC } from "react";
{%- if values.ui_framework == 'mui' %}
import { Container, Typography, Box, Button } from "@mui/material";
import { Link as RouterLink } from "react-router-dom";
{%- endif %}

export const About: FC = () => {
  return (
{%- if values.ui_framework == 'mui' %}
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h3" component="h1" gutterBottom>
          About
        </Typography>
        <Typography variant="body1" paragraph>
          ${{ values.description }}
        </Typography>
        <Typography variant="body1" paragraph>
          This application was created using the DevOps Platform scaffolder.
        </Typography>
        <Button component={RouterLink} to="/" variant="outlined">
          Back to Home
        </Button>
      </Box>
    </Container>
{%- else %}
    <main className="about">
      <h1>About</h1>
      <p>${{ values.description }}</p>
      <a href="/">Back to Home</a>
    </main>
{%- endif %}
  );
};
