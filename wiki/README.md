# Wiki Source

This directory contains the source files for the GitHub wiki at:
https://github.com/DaltonCalford/ScratchBird-driver/wiki

## Project Status

ScratchBird is in early alpha release. No binaries have been officially released at this time. The code is ready to be built and tested if you want to setup your own test environment.

If you are curious, clone the directories and have your friendly local AI analyse the code base (documentation is out of date except for specifications) - tell it to find out the capabilities of the project from the implemented source code, not the comments or documentation. This will give you a good understanding of what is done and what is going to be done.

The drivers and management interface (ScratchBird-drivers and ScratchRobin) are getting heavy testing and updating. They are getting multiple commits per day on average.

The initial preview will be a docker containing the database engine and an app-image or standalone executable so that you can test the project without any problems of getting rid of it afterward.

This project has become my answer to the constant "Damn I wish I had the ability to...." issues I have encountered over 35 years of database use.

I have been seeing multiple clones of my project(s) via the tracker but I have not received any feedback yet - don't be afraid, I need feedback and I don't bite.

I am sure there are things others have encountered over the years and wish they had a tool to cover it.

Thanks for your interest in the project.

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
