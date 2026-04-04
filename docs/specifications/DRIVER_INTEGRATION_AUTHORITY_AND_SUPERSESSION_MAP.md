# Driver Integration Authority And Supersession Map

Status: Current
Last Updated: 2026-04-03

## Classification Rules

- `authoritative_active`: current Beta 1 closure source
- `supporting_template_only`: retained as reference/template only
- `future_backlog`: not part of current active closure
- `superseded_by_top_level_spec`: historical subtree retained, but a top-level doc is authoritative

## Targeted Superseded Directories

| Directory | Classification | Authoritative Doc |
| --- | --- | --- |
| `docs/specifications/integrations/tools/dbeaver` | `superseded_by_top_level_spec` | `../../application-reference/DBEAVER_COMPATIBILITY_SPECIFICATION.md` |
| `docs/specifications/integrations/tools/metabase` | `superseded_by_top_level_spec` | `../../application-reference/METABASE_COMPATIBILITY_SPECIFICATION.md` |
| `docs/specifications/integrations/orm/sqlalchemy` | `superseded_by_top_level_spec` | `../../application-reference/SQLALCHEMY_COMPATIBILITY_SPECIFICATION.md` |
| `docs/specifications/integrations/orm/hibernate-jpa` | `superseded_by_top_level_spec` | `../../application-reference/HIBERNATE_COMPATIBILITY_SPECIFICATION.md` |
| `docs/specifications/integrations/orm/prisma` | `superseded_by_top_level_spec` | `../../application-reference/PRISMA_COMPATIBILITY_SPECIFICATION.md` |
| `docs/specifications/integrations/orm/typeorm` | `superseded_by_top_level_spec` | `../../application-reference/TYPEORM_COMPATIBILITY_SPECIFICATION.md` |

## Group-Level Classification

| Group | Classification | Notes |
| --- | --- | --- |
| `docs/specifications/integrations/drivers/` | `supporting_template_only` | Current active driver authority lives under `docs/specifications/drivers/` and the top-level driver specs. |
| `docs/specifications/integrations/orm/` | `future_backlog` except targeted superseded directories | Keep for future expansion, not active Beta 1 authority. |
| `docs/specifications/integrations/tools/` | `future_backlog` except targeted superseded directories | DBeaver and Metabase are covered by top-level compatibility specs. |
| `docs/specifications/integrations/apps/` | `future_backlog` | Not part of the current active driver/adaptor closure program. |
| `docs/specifications/integrations/bigdata/` | `future_backlog` | Not part of the current active closure program. |
| `docs/specifications/integrations/cloud/` | `future_backlog` | Not part of the current active closure program. |
