#!/bin/bash

set -euo pipefail

function installTravisTools {
  mkdir ~/.local
  curl -sSL https://github.com/SonarSource/travis-utils/tarball/v21 | tar zx --strip-components 1 -C ~/.local
  source ~/.local/bin/install
}

# required as long as version 1.1-SNAPSHOT is being used
build_snapshot "SonarSource/license-headers"

mvn package -B -V -e
