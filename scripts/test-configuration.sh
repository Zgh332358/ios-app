#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/resonance-config-tests.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT HUP INT TERM
swiftc \
  Resonance/Services/KeyValueStorage.swift \
  Resonance/Services/WebAppConfiguration.swift \
  Resonance/Services/ConfigurationService.swift \
  tests/WebAppConfigurationTests.swift \
  -o "$work_dir/config-tests"
"$work_dir/config-tests"
