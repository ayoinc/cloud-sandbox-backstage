import compression from 'compression';
import cors from 'cors';
import express, { type ErrorRequestHandler, type Express } from 'express';
import helmet from 'helmet';
import pinoHttp from 'pino-http';
import { logger } from './logger';
import { apiRouter } from './routes/api';
import { healthRouter } from './routes/health';

export function createApp(): Express {
  const app = express();

  app.use(helmet());
  app.use(cors());
  app.use(compression());
  app.use(express.json());
  app.use(pinoHttp({ logger }));

  app.use('/health', healthRouter);
  app.use('/api', apiRouter);

  app.use((_req, res) => {
    res.status(404).json({ error: 'Not Found' });
  });

  // Express recognises an error handler by its four parameters. Middleware
  // such as the JSON body parser reports client errors with a 4xx status.
  const errorHandler: ErrorRequestHandler = (err, req, res, _next) => {
    if (typeof err.status === 'number' && err.status < 500) {
      res.status(err.status).json({ error: err.message });
      return;
    }
    req.log.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  };
  app.use(errorHandler);

  return app;
}
