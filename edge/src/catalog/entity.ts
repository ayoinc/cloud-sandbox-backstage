/**
 * The parts of a catalog entity the Worker reads. Entities in D1 were
 * validated by the Backstage catalog that produced them.
 */
export interface Entity {
  apiVersion: string;
  kind: string;
  metadata: {
    name: string;
    namespace?: string;
    title?: string;
    description?: string;
    annotations?: Record<string, string>;
    [key: string]: unknown;
  };
}

export interface LocationRef {
  type: string;
  target: string;
}

/** Splits a `type:target` reference, such as `url:https://...` or `dir:.`. */
export function parseLocationRef(
  ref: string | undefined,
): LocationRef | undefined {
  const separator = ref?.indexOf(':') ?? -1;
  if (!ref || separator < 1 || separator === ref.length - 1) {
    return undefined;
  }
  return { type: ref.slice(0, separator), target: ref.slice(separator + 1) };
}

/** Where the entity's source lives, falling back to where it was read from. */
export function sourceLocation(entity: Entity): LocationRef | undefined {
  const annotations = entity.metadata.annotations ?? {};
  return parseLocationRef(
    annotations['backstage.io/source-location'] ||
      annotations['backstage.io/managed-by-location'],
  );
}
