const encoder = new TextEncoder();
const decoder = new TextDecoder();

export function bytesToBase64(bytes: Uint8Array): string {
  let binary = '';
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary);
}

export function base64ToBytes(value: string): Uint8Array {
  return Uint8Array.from(atob(value), char => char.charCodeAt(0));
}

/** Standard base64 of UTF-8 JSON: the cursor format Backstage clients decode. */
export const encodeJson = (value: unknown) =>
  bytesToBase64(encoder.encode(JSON.stringify(value)));

/** Returns `undefined` when the input is not base64-encoded JSON. */
export function decodeJson(value: string): unknown {
  try {
    return JSON.parse(decoder.decode(base64ToBytes(value)));
  } catch {
    return undefined;
  }
}
