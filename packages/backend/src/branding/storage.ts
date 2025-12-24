/**
 * =============================================================================
 * Branding Settings Storage Operations
 * =============================================================================
 *
 * MinIO/S3 storage operations for logo files.
 *
 * =============================================================================
 */

import {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
} from '@aws-sdk/client-s3';
import type { LoggerService } from '@backstage/backend-plugin-api';
import { MIME_TO_EXTENSION } from './types';

/**
 * Create an S3 client configured for MinIO
 */
export function createS3Client(
  endpoint: string,
  accessKeyId: string,
  secretAccessKey: string,
): S3Client {
  return new S3Client({
    endpoint,
    region: 'us-east-1',
    credentials: {
      accessKeyId: accessKeyId || '',
      secretAccessKey: secretAccessKey || '',
    },
    forcePathStyle: true, // Required for MinIO
  });
}

/**
 * Get file extension from MIME type
 */
export function getExtension(mimeType: string): string {
  return MIME_TO_EXTENSION[mimeType] || 'png';
}

/**
 * Upload a logo file to S3/MinIO
 */
export async function uploadLogo(
  s3Client: S3Client,
  bucket: string,
  file: { buffer: Buffer; mimetype: string },
  logoType: 'full' | 'icon',
  logger: LoggerService,
): Promise<string> {
  const ext = getExtension(file.mimetype);
  const key = `logos/logo-${logoType}.${ext}`;

  await s3Client.send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      Body: file.buffer,
      ContentType: file.mimetype,
      CacheControl: 'max-age=31536000', // 1 year cache
    }),
  );

  // Use /assets/ path which is proxied by nginx to MinIO
  const url = `/assets/${key}?t=${Date.now()}`;
  logger.info(`Uploaded logo-${logoType} to ${key}`);
  return url;
}

/**
 * Delete all logo files from S3/MinIO
 */
export async function deleteLogos(
  s3Client: S3Client,
  bucket: string,
  logger: LoggerService,
): Promise<void> {
  const extensions = ['png', 'svg', 'jpg', 'webp', 'gif'];

  for (const ext of extensions) {
    for (const logoType of ['full', 'icon']) {
      try {
        await s3Client.send(
          new DeleteObjectCommand({
            Bucket: bucket,
            Key: `logos/logo-${logoType}.${ext}`,
          }),
        );
      } catch {
        // Ignore errors if files don't exist
      }
    }
  }

  logger.info('Deleted logo files from storage');
}
