# Wiki Source

This directory contains the source files for the GitHub wiki at:
https://github.com/DaltonCalford/ScratchBird-driver/wiki

## Project Status

ScratchBird-driver is in **Initial Early Beta release (`0.1.0`)**.
Completed drivers are promoted to `0.1.0`, and incomplete drivers remain in active development for post-`0.1.0`.

## Setup (first time)

The wiki is a separate git repository. To initialize:

```bash
cd wiki
git init
git remote add origin https://github.com/DaltonCalford/ScratchBird-driver.wiki.git
```

## Pushing to the wiki

After editing wiki pages:

```bash
cd wiki
git add .
git commit -m "Update wiki"
git push origin master
```

Note: GitHub wikis use the `master` branch by default.

## Pulling wiki changes

If changes were made directly on GitHub:

```bash
cd wiki
git pull origin master
```

## File naming

- `Home.md` - Wiki home page
- `_Sidebar.md` - Navigation sidebar
- Other files use kebab-case (e.g., `Getting-Started.md`)
