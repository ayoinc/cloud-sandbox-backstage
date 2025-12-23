import request from 'supertest';
import { app } from '../index';

describe('Health Endpoints', () => {
  it('GET /health should return healthy status', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body.status).toBe('healthy');
  });

  it('GET /health/ready should return ready status', async () => {
    const response = await request(app).get('/health/ready');
    expect(response.status).toBe(200);
    expect(response.body.ready).toBe(true);
  });

  it('GET /health/live should return alive status', async () => {
    const response = await request(app).get('/health/live');
    expect(response.status).toBe(200);
    expect(response.body.alive).toBe(true);
  });
});

describe('API Endpoints', () => {
  it('GET /api should return welcome message', async () => {
    const response = await request(app).get('/api');
    expect(response.status).toBe(200);
    expect(response.body.message).toContain('Welcome');
  });
});
