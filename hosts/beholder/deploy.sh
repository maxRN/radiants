#!/usr/bin/env bash
# Build beholder's system on this machine (aarch64-linux goes to a remote/linux
# builder), copy it over and activate it. The Pi never evaluates or builds.
#
#   hosts/beholder/deploy.sh [test|switch|boot]   (default: test)
#
# `test` activates without touching the boot default, so a reboot undoes it.
set -euo pipefail

action=${1:-test}
target=${TARGET:-root@beholder}
flake=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)

system=$(nix build --no-link --print-out-paths "$flake#nixosConfigurations.beholder.config.system.build.toplevel")
# Builder outputs are unsigned; root on beholder is a trusted user, so it may skip the check.
nix copy --no-check-sigs --to "ssh-ng://$target" "$system"

if [ "$action" != test ]; then
  ssh "$target" nix-env -p /nix/var/nix/profiles/system --set "$system"
fi
ssh "$target" "$system/bin/switch-to-configuration" "$action"
