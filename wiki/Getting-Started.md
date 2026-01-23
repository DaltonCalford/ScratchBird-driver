# Getting Started

All drivers connect to the ScratchBird native listener over SBWP v1.1 and
require TLS 1.3.

Binary transfer is required for all drivers.

## Common DSN

URI:

```
scratchbird://user:password@host:3092/database?sslmode=require
```

Key-value:

```
host=localhost port=3092 dbname=mydb user=myuser password=mypass
```

See the canonical DSN spec:
https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md

## Quick Examples

- Go: https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/getting-started/go.md
- Python: https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/getting-started/python.md
- Node.js: https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/getting-started/node.md
