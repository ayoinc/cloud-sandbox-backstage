import { Router } from 'express';
import { config } from '../config';

const router = Router();

router.get('/', (_req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: config.name,
    environment: config.environment,
  });
});

router.get('/ready', (_req, res) => {
  // Add readiness checks here (database, cache, etc.)
  res.json({ ready: true });
});

router.get('/live', (_req, res) => {
  res.json({ alive: true });
});

export { router as healthRouter };
