import type { FC } from "react";
{%- if values.ui_framework == 'mui' %}
import { Container, Typography, Button, Box, Stack } from "@mui/material";
import { Link as RouterLink } from "react-router-dom";
{%- endif %}

export const Home: FC = () => {
  return (
{%- if values.ui_framework == 'mui' %}
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Box sx={{ textAlign: "center", mb: 4 }}>
        <Typography variant="h2" component="h1" gutterBottom>
          ${{ values.name }}
        </Typography>
        <Typography variant="h5" color="text.secondary" paragraph>
          ${{ values.description }}
        </Typography>
        <Stack direction="row" spacing={2} justifyContent="center">
          <Button
            component={RouterLink}
            to="/about"
            variant="contained"
            size="large"
          >
            Learn More
          </Button>
          <Button
            href="https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}"
            variant="outlined"
            size="large"
            target="_blank"
            rel="noopener noreferrer"
          >
            View on GitHub
          </Button>
        </Stack>
      </Box>
    </Container>
{%- else %}
    <main className="home">
      <h1>${{ values.name }}</h1>
      <p>${{ values.description }}</p>
      <nav>
        <a href="/about">About</a>
      </nav>
    </main>
{%- endif %}
  );
};
