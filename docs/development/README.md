# Development Guides

This section covers build, test, packaging, release evidence, and later
server-verification workflows for the driver set.

The repo is currently in a mixed state:

- implemented lanes use these guides for ongoing release evidence and live proof
- newly promoted `planned_beta1` lanes now have deterministic build/verification
  contracts, but still require implementation before the server-verification
  packets can be executed

## Guides

- [Development notes](development-notes.md)
- [Build and test matrix](build-and-test.md)
- [Toolchain setup](toolchain-setup.md)
- [Conformance testing](conformance-testing.md)
- [Packaging and release](release-packaging.md)
- [Release evidence templates](release-evidence/README.md)
- [Server verification packets](server-verification/README.md)
- [Server-blocked remaining work](../audit/DRIVER_SERVER_BLOCKED_REMAINING_WORK.md)
