#!/bin/bash

set -euo pipefail

function installTravisTools {
  mkdir -p ~/.local
  curl -sSL https://github.com/SonarSource/travis-utils/tarball/v61 | tar zx --strip-components 1 -C ~/.local
  source ~/.local/bin/install
}

installTravisTools

source setup_promote_environment

source build_and_promote_and_notify

source release "sonarsource-public-releases"
