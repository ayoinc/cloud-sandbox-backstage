import { Router } from 'express';

const router = Router();

router.get('/', (req, res) => {
  res.json({
    message: 'Welcome to ${{ values.name }} API',
    version: '1.0.0',
  });
});

// Add your API routes here
router.get('/example', (req, res) => {
  res.json({
    data: 'Example endpoint',
  });
});

export { router as apiRouter };
