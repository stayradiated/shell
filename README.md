# My Computer

This is the docker image I use as my daily OS.

## Checking For Updates

Most software in the Dockerfile is pinned to a specific version. 

These are commands to find what the latest available version.

TODO: write a script to check everything and extract the versions

### NPM

```bash
npm outdated --global
```

### Node.js

```bash
curl --silent https://nodejs.org/dist/index.json |
jq -r 'sort_by(.date)|last|.version' 
```

### NVM

Check https://github.com/nvm-sh/nvm/releases

