# pi-topOS Build

This repository provides the build pipeline used for pi-topOS images. Go to https://www.pi-top.com/download for official releases!

## Build Types
All builds are kept for 90 days in accordance with GitHub Actions' artifacts storage policy.

### Release Candidate Builds

Go [here](https://github.com/pi-top/pi-topOS-Build/actions/workflows/bullseye-unstable.yml) for release candidate builds. These act as early release previews for pi-topOS. Packages are installed from PackageCloud's unstable repo, which is populated with packages that have had a GitHub Release.

### Preview Builds

Go [here](https://github.com/pi-top/pi-topOS-Build/actions/workflows/bullseye-unstable.yml) for preview builds. These act as early release previews for pi-topOS. Packages are installed from PackageCloud's unstable repo, which is populated with packages that have had a GitHub Release.

### Nightly Builds

Go [here](https://github.com/pi-top/pi-topOS-ansible-playbook/actions/workflows/bullseye-experimental.yml?query=event%3Aschedule) for nightly builds.

These act as bleeding edge previews of pi-topOS. Packages are installed from PackageCloud's experimental repo, which is populated with the latest master packages of all pi-topOS software.

## Using images from this repository

When you download an artifact from a GitHub Action workflow run, it will be named something like `experimental-bullseye-88` - you will need to unzip this before using, as this is an artifact-level zip which contains the actual pi-topOS zip as a 'build artifact' inside of it.
