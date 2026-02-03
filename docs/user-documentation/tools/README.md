# ScratchBird CLI Tools

This directory documents the CLI tools shipped with ScratchBird-driver.
All tools connect to ScratchBird over SBWP v1.1 or an emulated protocol.

## Tools

- [sb_isql](sb-isql.md) - Native ScratchBird interactive SQL shell
- [sb_fb_isql](sb-fb-isql.md) - Firebird protocol script runner
- [sb_pg_isql](sb-pg-isql.md) - PostgreSQL protocol script runner
- [sb_my_isql](sb-my-isql.md) - MySQL protocol script runner
- [sb_admin](sb-admin.md) - Administration CLI
- [sb_backup](sb-backup.md) - Backup/restore CLI
- [sb_security](sb-security.md) - User/role management CLI
- [sb_verify](sb-verify.md) - Database verification CLI
- [sbdriver-conformance](sbdriver-conformance.md) - SBWP conformance adapter

## Notes

- CLI tools are built from the top-level CMake project.
- The emulated protocol tools (`sb_fb_isql`, `sb_pg_isql`, `sb_my_isql`) are
  intended for script testing against ScratchBird's emulation listeners.
