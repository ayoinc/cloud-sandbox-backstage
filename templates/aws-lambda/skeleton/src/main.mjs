// Lambda entry point for Node.js runtimes (handler: main.handler).

export const handler = async () => {
  const environment = process.env.ENVIRONMENT ?? 'unknown';

  return {
    statusCode: 200,
    body: JSON.stringify({
      message: 'Hello from ${{ values.name }}',
      environment,
    }),
  };
};
