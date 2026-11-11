import { Router } from 'express';
import { config } from '../config';
import { methodNotAllowed } from './methodNotAllowed';

const router = Router();

router
  .route('/')
  .get((_req, res) => {
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      service: config.name,
      environment: config.environment,
    });
  })
  .all(methodNotAllowed);

router
  .route('/ready')
  .get((_req, res) => {
    // Add readiness checks here (database, cache, etc.)
    res.json({ ready: true });
  })
  .all(methodNotAllowed);

router
  .route('/live')
  .get((_req, res) => {
    res.json({ alive: true });
  })
  .all(methodNotAllowed);

export { router as healthRouter };
