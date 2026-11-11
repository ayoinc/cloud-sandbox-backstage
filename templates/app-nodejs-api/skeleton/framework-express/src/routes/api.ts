import { Router } from 'express';
import { config } from '../config';

const router = Router();

router.get('/', (_req, res) => {
  res.json({
    message: `Welcome to ${config.name} API`,
    version: '1.0.0',
  });
});

// Add your API routes here
router.get('/example', (_req, res) => {
  res.json({
    data: 'Example endpoint',
  });
});

export { router as apiRouter };
