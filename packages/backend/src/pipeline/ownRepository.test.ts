import { Entity } from '@backstage/catalog-model';
import { OwnRepositoryProcessor } from './ownRepository';

const SLUG = 'github.com/project-slug';
const OWN = 'https://github.com/acme/portal';

const entity = (
  kind: string,
  annotations?: Record<string, string>,
): Entity => ({
  apiVersion: 'backstage.io/v1alpha1',
  kind,
  metadata: { name: 'example', annotations },
});

const fromUrl = (target: string) => ({ type: 'url', target });

describe('OwnRepositoryProcessor', () => {
  const processor = new OwnRepositoryProcessor('acme/portal', OWN);
  const slugOf = async (
    input: Entity,
    location: { type: string; target: string },
  ) =>
    (await processor.preProcessEntity(input, location)).metadata.annotations?.[
      SLUG
    ];

  it('names the portal repository on its components and templates', async () => {
    const location = fromUrl(`${OWN}/tree/main/catalog/a/catalog-info.yaml`);
    expect(await slugOf(entity('Component'), location)).toBe('acme/portal');
    expect(await slugOf(entity('Template'), location)).toBe('acme/portal');
  });

  it('keeps the other annotations of the entity', async () => {
    const result = await processor.preProcessEntity(
      entity('Component', { 'backstage.io/techdocs-ref': 'dir:.' }),
      fromUrl(`${OWN}/blob/main/catalog-info.yaml`),
    );
    expect(result.metadata.annotations).toEqual({
      'backstage.io/techdocs-ref': 'dir:.',
      [SLUG]: 'acme/portal',
    });
  });

  it('matches the repository address in any letter case', async () => {
    expect(
      await slugOf(
        entity('Component'),
        fromUrl('https://github.com/Acme/Portal/blob/main/catalog-info.yaml'),
      ),
    ).toBe('acme/portal');
  });

  it('keeps a repository the entity names itself', async () => {
    expect(
      await slugOf(
        entity('Component', { [SLUG]: 'ansible/awx' }),
        fromUrl(`${OWN}/blob/main/catalog-info.yaml`),
      ),
    ).toBe('ansible/awx');
  });

  it('leaves entities of other repositories alone', async () => {
    for (const target of [
      'https://github.com/acme/service/blob/main/catalog-info.yaml',
      'https://github.com/acme/portal-fork/blob/main/catalog-info.yaml',
      'https://github.com/other/portal/blob/main/catalog-info.yaml',
    ]) {
      expect(
        await slugOf(entity('Component'), fromUrl(target)),
      ).toBeUndefined();
    }
  });

  it('leaves entities read from a checkout alone', async () => {
    expect(
      await slugOf(entity('Component'), {
        type: 'file',
        target: '/work/portal/catalog/a/catalog-info.yaml',
      }),
    ).toBeUndefined();
  });

  it('leaves kinds without a pipeline alone', async () => {
    const location = fromUrl(`${OWN}/blob/main/catalog/systems.yaml`);
    for (const kind of ['System', 'Domain', 'API', 'Resource', 'Group']) {
      expect(await slugOf(entity(kind), location)).toBeUndefined();
    }
  });
});
