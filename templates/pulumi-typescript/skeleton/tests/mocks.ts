import * as pulumi from "@pulumi/pulumi";

/**
 * Replaces the Pulumi engine with an in-memory one: every resource gets an ID
 * and keeps its inputs, nothing is created. The tests need neither credentials
 * nor a Pulumi backend.
 */
export function useMocks(): void {
  pulumi.runtime.setMocks(
    {
      newResource(args: pulumi.runtime.MockResourceArgs) {
        return {
          id: `${args.name}-id`,
          state: {
            ...args.inputs,
            name: args.inputs.name ?? args.name,
            arn: `arn:aws:mock:::${args.name}`,
            bucket: args.inputs.bucket ?? args.name,
          },
        };
      },
      call(args: pulumi.runtime.MockCallArgs) {
        if (args.token === "gcp:storage/getProjectServiceAccount:getProjectServiceAccount") {
          return {
            member:
              "serviceAccount:service-123456789012@gs-project-accounts.iam.gserviceaccount.com",
          };
        }
        return args.inputs;
      },
    },
    "test-project",
    "test",
    false,
  );
  pulumi.runtime.setConfig("gcp:region", "${{ values.region }}");
}

/** Waits for an output, or for several, and returns the values. */
export function resolve<T>(value: pulumi.Input<T>): Promise<pulumi.Unwrap<T>> {
  return new Promise((done) => pulumi.output(value).apply(done));
}
