// Package version identifies the running build.
package version

// Name is the service name reported in logs, metrics and traces.
const Name = "${{ values.serviceName }}"

// Version is the release version. Release builds replace it with
// -ldflags "-X ${{ values.modulePath }}/internal/version.Version=<tag>".
var Version = "${{ values.serviceVersion }}"
