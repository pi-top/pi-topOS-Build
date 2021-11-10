# pi-topOS Build

This repository provides the build pipeline used for official pi-topOS images.

## Build Types
### Nightly Builds

Go [here](https://github.com/pi-top/pi-topOS-ansible-playbook/actions/workflows/bullseye-experimental.yml?query=event%3Aschedule) for nightly builds.

These act as bleeding edge previews of pi-topOS. Packages are installed from PackageCloud's experimental repo, which is populated with the latest master packages of all pi-topOS software.

GitHub Actions' artifacts are kept for 90 days.

### Preview Builds

Go [here](https://github.com/pi-top/pi-topOS-Build/actions/workflows/bullseye-unstable.yml) for preview builds. These act as early release previews for pi-topOS. Packages are installed from PackageCloud's unstable repo, which is populated with packages that have had a GitHub Release.

### Official Releases

There are currently no official releases with this build toolchain.

## Using images from this repository

When you download an artifact from a GitHub Action workflow run, it will be named something like `experimental-bullseye-88` - you will need to unzip this before using, as this is an artifact-level zip which contains the actual pi-topOS zip as a 'build artifact' inside of it.
