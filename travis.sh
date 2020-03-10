#!/bin/bash

set -euo pipefail

function installTravisTools {
  mkdir -p ~/.local
  curl -sSL https://github.com/SonarSource/travis-utils/tarball/e7ab8e81288cf22deb86918a63d19d0915cdaf5f | tar zx --strip-components 1 -C ~/.local
  source ~/.local/bin/install
}

installTravisTools

source setup_promote_environment

source build_and_promote_and_notify

source do_parent_pom_release "sonarsource-public-releases"
