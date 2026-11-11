// Prints a token for local development, signed with JWT_SECRET.
//
//   npm run token                 a token with the admin role
//   npm run token -- viewer       a token with the given roles
import { SignJWT } from 'jose';
import { loadConfig } from '../src/config.js';

const { auth } = loadConfig();
if (!auth.enabled || auth.provider !== 'jwt' || !auth.jwtSecret) {
  console.error('Tokens can only be made when AUTH_ENABLED=true, AUTH_PROVIDER=jwt and JWT_SECRET is set.');
  process.exit(1);
}

const roles = process.argv.length > 2 ? process.argv.slice(2) : ['admin'];
const token = new SignJWT({ [auth.rolesClaim]: roles }).setProtectedHeader({ alg: 'HS256' }).setSubject('local-developer').setIssuedAt().setExpirationTime('8h');
if (auth.issuer) token.setIssuer(auth.issuer);
if (auth.audience) token.setAudience(auth.audience);
console.log(await token.sign(new TextEncoder().encode(auth.jwtSecret)));
