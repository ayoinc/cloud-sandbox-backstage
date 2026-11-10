import { createFrontendModule } from '@backstage/frontend-plugin-api';
import { HomePageWidgetBlueprint } from '@backstage/plugin-home-react/alpha';
import { MarkdownContent } from '@backstage/core-components';

const content = `
## Welcome to Cloud Sandbox

The Solirius Reply developer portal: one place to find services, APIs and
documentation, and to create new components from approved templates.

### Get started

- **Find software**: browse the [software catalog](/catalog)
- **Create something new**: start from a [template](/create)
- **Read the docs**: open [documentation](/docs) for any service
- **Register existing work**: add a repository through
  [catalog import](/catalog-import)

### Get help

- [Portal source and issues](https://github.com/ayointegral/cloud-sandbox-backstage)
- [Backstage documentation](https://backstage.io/docs)
`;

const gettingStartedWidget = HomePageWidgetBlueprint.make({
  name: 'getting-started',
  params: {
    name: 'GettingStarted',
    title: 'Get started',
    description: 'How to find, create and document software in Cloud Sandbox',
    components: async () => ({
      Content: () => <MarkdownContent content={content} />,
    }),
  },
});

export const homeModule = createFrontendModule({
  pluginId: 'home',
  extensions: [gettingStartedWidget],
});
