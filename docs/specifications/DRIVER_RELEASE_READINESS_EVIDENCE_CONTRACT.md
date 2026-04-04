# Driver Release Readiness Evidence Contract (Shared)

Status: Draft
Last Updated: 2026-04-03

## Purpose

Define the mandatory release-evidence pack for every installable ScratchBird
driver so a release can be defended with executable proof instead of narrative
claims.

This contract expands the shared conformance harness into a full
release-readiness gate. Every shipped driver must provide:

- contract tests
- conformance reports
- compatibility matrices
- performance numbers
- known-gap lists
- stable packaging and release cadence

## Scope

This contract applies to every publishable or installable driver lane in this
repository, including:

- `cli`
- `cpp`
- `dart`
- `dotnet`
- `elixir`
- `go`
- `jdbc`
- `mojo`
- `node`
- `odbc`
- `pascal`
- `php`
- `python`
- `r`
- `ruby`
- `rust`
- `swift`

Installable integration packages that ship a driver-facing deliverable, such as
BI/ORM/plugin adapters, must satisfy this contract in addition to their
integration-specific specification set.

## Release Evidence Pack Location

Every driver release candidate must stage an evidence pack at:

`release/readiness/<driver-id>/<version>/`

Example:

`release/readiness/python/0.1.0/`

The path is deterministic so release automation and low-reasoning
implementation agents do not need to infer where evidence belongs.

## Required Files

Every release evidence pack must contain all of the following files.

### 1. `CONTRACT_TEST_RESULTS.json`

Machine-readable raw or normalized test outcomes for the driver.

Required content:

- `schema_version`
- `driver_id`
- `driver_version`
- `commit`
- `build_timestamp_utc`
- `runtime_matrix`
- `suite_results`
- `pass_count`
- `fail_count`
- `skip_count`
- `skips`
- `artifact_links`

Required suite families:

- unit contract tests
- deterministic integration contract tests
- live DSN-backed conformance tests
- metadata contract tests
- error-mapping contract tests
- resource-lifecycle/cancel/timeout contract tests
- packaging smoke tests for install/import/load

Released drivers must not hide required capability failures behind silent
default skips. Any skip must name the gating reason explicitly.

### 2. `CONFORMANCE_REPORT.md`

Human-readable summary of how the driver satisfied
`DRIVER_CONFORMANCE_TEST_HARNESS.md`.

Required content:

- tested protocol version
- tested capability matrix
- executed manifest/suite list
- required SQLSTATE/error-path coverage summary
- metadata family coverage summary
- deviations, waivers, and rationale
- comparison to previous released version
- final release verdict (`pass`, `pass_with_known_gaps`, `blocked`)

### 3. `COMPATIBILITY_MATRIX.md`

Driver-specific support matrix.

Required rows or sections:

- operating systems and architectures
- runtime/compiler/VM versions
- package-manager/registry targets
- supported ScratchBird server versions and protocol versions
- TLS/back-end library dependencies
- framework/adapter compatibility where relevant (`DB-API`, `ADO.NET`,
  `database/sql`, `PDO`, `DBI`, `JDBC`, `ODBC`, `SwiftPM`, `Hex`, `pub.dev`)
- unsupported combinations and explicit caveats

### 4. `PERFORMANCE_NUMBERS.md`

Numerical performance evidence, not adjectives.

Required workloads:

- connect/auth latency
- simple query latency
- prepared execute throughput or latency
- streaming fetch throughput for large result sets
- peak memory behavior during large-result streaming
- metadata-call latency for the primary metadata API surface
- cancel/timeout reaction latency
- batch/bulk path numbers when the driver exposes a batch API

Every benchmark entry must include:

- environment description
- dataset/fixture description
- driver build/version
- server build/version
- sample count
- metric units
- previous-release comparison when available

### 5. `KNOWN_GAPS.md`

Mandatory, explicit list of remaining deficits for the driver. A released
driver may have known gaps, but they must be disclosed.

Each gap entry must include:

- stable gap id
- severity
- subsystem
- user-visible behavior
- workaround, if any
- release-blocking yes/no
- target milestone/version

If no gaps remain for a reviewed surface, the file must still exist and record
that the area was reviewed and found clear.

### 6. `PACKAGING_AND_RELEASE_CADENCE.md`

Driver-specific packaging and lifecycle contract.

Required content:

- package names/coordinates for every registry or distribution channel
- artifact list and checksum/signing state
- publish workflow and required credentials
- prerelease/stable channel naming
- semantic-versioning policy
- release cadence statement
- support window and deprecation policy
- rollback/yank policy
- maintainer ownership expectations, including 2FA-sensitive registries

If a package is intentionally not yet publishable, that must be stated here as
an explicit blocked state, not implied by omission.

### 7. `SUMMARY.json`

Top-level release verdict for automation.

Required fields:

- `driver_id`
- `version`
- `release_channel`
- `release_readiness`
- `blocking_findings`
- `artifact_manifest`

## Minimum Release Rules

1. No driver may be labeled `beta-ready`, `rc`, or `stable` without a complete
   evidence pack.
2. Missing `CONTRACT_TEST_RESULTS.json` means the driver is not releaseable.
3. Missing `CONFORMANCE_REPORT.md` means conformance claims are not
   reviewable.
4. Missing `COMPATIBILITY_MATRIX.md` means support claims are incomplete.
5. Missing `PERFORMANCE_NUMBERS.md` means performance claims are unsupported.
6. Missing `KNOWN_GAPS.md` means unresolved issues are being hidden.
7. Missing `PACKAGING_AND_RELEASE_CADENCE.md` means the release process is not
   operationally stable.

## Relationship To Existing Specs

- Protocol-level behavior remains defined by
  `DRIVER_CONFORMANCE_TEST_HARNESS.md`.
- DSN/config rules remain defined by `DRIVER_DSN_AND_CONFIG_STANDARD.md`.
- Type coverage remains defined by `TYPE_MAPPING_MATRIX.md`.
- Metadata coverage remains defined by `METADATA_SCHEMA_CONTRACT.md` and
  `DRIVER_METADATA_JDBC_ODBC_MAPPING.md`.
- Packaging mechanics remain described by `docs/development/release-packaging.md`
  and `docs/release/DRIVER_PACKAGE_SUBMISSION_GUIDE.md`.

This document does not replace those specifications; it defines the release
evidence required to prove they were met.

<!-- release-evidence-template-pack:start -->

## Template Pack

The canonical starter templates for every required evidence file now live in:

- `docs/development/release-evidence/README.md`

Low-reasoning implementation or release agents should copy those templates
into `release/readiness/<driver-id>/<version>/` and fill them with measured
lane output rather than inventing file layouts ad hoc.

<!-- release-evidence-template-pack:end -->
