import React from 'react';
import { EntityAboutCard } from '@backstage/plugin-catalog';
import { useIsGuest } from '../../hooks/useIsGuest';

type EntityAboutCardProps = React.ComponentProps<typeof EntityAboutCard>;

export const GuestAwareAboutCard = (props: EntityAboutCardProps) => {
  const isGuest = useIsGuest();

  if (isGuest) {
    return <EntityAboutCard {...props} />;
  }

  return <EntityAboutCard {...props} />;
};
