# Toolchain Setup (CI + Local)

This guide captures the supported install flows for toolchains that are not
preinstalled on typical CI images. Use these commands when provisioning
builders for ScratchBird drivers.

## Dart (Ubuntu 24.04)

Install Dart from the official Dart apt repository:

```bash
sudo apt-get update && sudo apt-get install -y apt-transport-https wget gpg
wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub \
  | sudo gpg --dearmor -o /usr/share/keyrings/dart.gpg
echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' \
  | sudo tee /etc/apt/sources.list.d/dart_stable.list
sudo apt-get update && sudo apt-get install -y dart
dart --version
```

## Mojo (Linux)

Mojo is distributed via Modular's conda channels. The recommended workflow is
Pixi; it is fast and supports lockfiles.

```bash
curl -fsSL https://pixi.sh/install.sh | sh
mkdir -p /tmp/mojo-env && cd /tmp/mojo-env
pixi init . -c https://conda.modular.com/max-nightly/ -c conda-forge
pixi add mojo
pixi run mojo --version
```

For repository tests, use `pixi run mojo ...` from the env directory, or run
`pixi shell` to activate the environment before invoking `mojo`.
