# fuel.nix

A Nix flake for the Fuel Labs ecosystem. **https://fuel.network**

Each night at midnight (UTC) this repo is automatically updated with the latest
stable and nightly releases of all fuel packages. Builds are tested and cached
for `x86_64-linux`, `x86_64-darwin` and `aarch64-darwin` systems.

See the [**Quick Start**][fuel-nix-quick-start] guide from
[**the book**][fuel-nix-book] to get started.

# To run in docker:

build `fuel-nix` :

```
docker build -t fuel-nix -f docker/Dockerfile .
```

jump into it with shell:

```
docker run -it fuel-nix
```

if you wanna mount your current dictory to have access to files from inside container:

```
docker run -it -v $(pwd):/pwd fuel-nix   # and inside docker `cd /pwd`
```

[fuel-nix-book]: https://nix.fuel.network
[fuel-nix-quick-start]: https://nix.fuel.network/quick-start
