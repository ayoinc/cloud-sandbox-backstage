import type { RequestHandler } from 'express';

/**
 * Ends a route's chain: `router.route('/x').get(handler).all(methodNotAllowed)`.
 * A method the route does not offer is answered with 405 and the methods it
 * does, instead of the 404 that says the resource is not there at all.
 */
export const methodNotAllowed: RequestHandler = (req, res) => {
  const allow = Object.keys(req.route.methods)
    .filter((method) => method !== '_all')
    .map((method) => method.toUpperCase())
    .join(', ');
  res.set('Allow', allow).status(405).json({ error: 'Method Not Allowed' });
};
