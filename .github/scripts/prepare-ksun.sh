#!/usr/bin/env bash
set -euo pipefail
KSUN_COMMIT=188cf08dae644d6ede3806c258b7af11d36dca93
MANAGER_COMMIT=3f64b8ce28279ed96118212bdbfc49010dbc8936
rm -rf kernel_source/KernelSU-Next
git clone --quiet https://github.com/pershoot/KernelSU-Next kernel_source/KernelSU-Next
cd kernel_source/KernelSU-Next
# dev-susfs is rebased frequently; fetch the pinned object explicitly.
git fetch --quiet origin "$KSUN_COMMIT"
git checkout --quiet -B dev-susfs "$KSUN_COMMIT"
git merge-base --is-ancestor v3.4.1 HEAD
git merge-base --is-ancestor "$MANAGER_COMMIT" HEAD
# The intervening upstream commit changes only scripts/ksunextbot.py.
# Anchor versioning to the official commit that produced both signed APKs.
git update-ref refs/remotes/origin/dev "$MANAGER_COMMIT"
test "$(git merge-base HEAD refs/remotes/origin/dev)" = "$MANAGER_COMMIT"
test "$(git rev-list --count "$MANAGER_COMMIT")" = 3339
printf 'KernelSU commit: %s\nManager base: %s\nVersion code: 33339\n' "$KSUN_COMMIT" "$MANAGER_COMMIT"
