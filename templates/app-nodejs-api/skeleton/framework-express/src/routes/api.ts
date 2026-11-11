import { Router } from 'express';
import { config } from '../config';
import { methodNotAllowed } from './methodNotAllowed';

const router = Router();

router
  .route('/')
  .get((_req, res) => {
    res.json({
      message: `Welcome to ${config.name} API`,
      version: '1.0.0',
    });
  })
  .all(methodNotAllowed);

// Add your API routes here. End each with .all(methodNotAllowed), so a
// method the route does not offer is answered with 405.
router
  .route('/example')
  .get((_req, res) => {
    res.json({
      data: 'Example endpoint',
    });
  })
  .all(methodNotAllowed);

export { router as apiRouter };
