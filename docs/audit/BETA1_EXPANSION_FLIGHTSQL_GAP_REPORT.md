# Beta 1 Expansion Flight SQL Gap Report

Status: Current
Lane: `flightsql`
Benchmark: `Apache Arrow Flight SQL client stack`
Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/flightsql/BEST_IN_CLASS_RESEARCH.md`

## Current ScratchBird Truth

- the lane is active Beta 1 authority
- the top-level spec and public docs exist
- implementation is not started
- no live proof exists yet

## Functional Gaps

- no Flight SQL transport/session implementation exists
- no ticket-based query execution or prepared-statement lifecycle exists
- no dedicated analytical Arrow stream lane exists for this surface yet

## Metadata And Type Gaps

- no Flight SQL metadata bridge exists yet
- no lane-local mapping for ScratchBird errors into Flight SQL status surfaces exists
- no partitioned-read or schema-metadata translation has been implemented

## Packaging And Tooling Gaps

- no client package layout or SDK guidance exists yet
- no interop guidance exists for Arrow/Flight client stacks above the transport
- no dedicated performance harness exists for the lane

## Live-Proof-Only Gaps

- channel/auth behavior and cancellation timing need live proof
- Arrow stream integrity and partitioned execution need live proof
- throughput claims require real-server benchmarking

## Offline Closure Target

Offline closure is achieved when the lane documents completely specify the
transport contract, metadata contract, package expectations, and later proof
commands so implementation no longer requires guesswork.
