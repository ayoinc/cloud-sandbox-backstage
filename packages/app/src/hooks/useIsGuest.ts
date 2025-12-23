import { identityApiRef, useApi } from '@backstage/core-plugin-api';
import { useAsync } from 'react-use';

export const useIsGuest = () => {
  const identityApi = useApi(identityApiRef);
  const { value: identity } = useAsync(
    () => identityApi.getBackstageIdentity(),
    [identityApi],
  );
  return identity?.userEntityRef === 'user:development/guest';
};
