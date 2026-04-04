# Reference Packets

Research packets and benchmark-reference material used to drive driver and
adapter specification closure.

## Current Packets

- [best_in_class_driver_research_2026-04-03/README.md](best_in_class_driver_research_2026-04-03/README.md)
  Core best-in-class benchmark packet for the original Beta 1 driver, CLI, and
  adapter lanes.
- [beta1_expansion_server_independent_2026-04-03/README.md](beta1_expansion_server_independent_2026-04-03/README.md)
  Benchmark packet for the ten newly promoted Beta 1 expansion lanes:
  `r2dbc`, `adbc`, `flightsql`, `julia`, `perl`, `dbt`, `airbyte`,
  `powerbi`, `tableau`, and `looker`.

## How To Use This Directory

- use the research packets together with [../audit/README.md](../audit/README.md)
  when expanding or implementing a lane
- use [../specifications/DRIVER_LANE_AUTHORITY_INDEX.md](../specifications/DRIVER_LANE_AUTHORITY_INDEX.md)
  to find each lane’s authoritative spec and verification packet
- use [../audit/DRIVER_SERVER_BLOCKED_REMAINING_WORK.md](../audit/DRIVER_SERVER_BLOCKED_REMAINING_WORK.md)
  to identify which proof steps still require a live ScratchBird server
