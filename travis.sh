#!/bin/bash

set -euo pipefail

function installTravisTools {
  mkdir ~/.local
  curl -sSL https://github.com/SonarSource/travis-utils/tarball/v28 | tar zx --strip-components 1 -C ~/.local
  source ~/.local/bin/install
}

installTravisTools

if [[ $CURRENT_VERSION =~ "-SNAPSHOT" ]]; then
  echo "======= Found SNAPSHOT version ======="
  # Do not deploy a SNAPSHOT version but the release version related to this build
  set_maven_build_version $TRAVIS_BUILD_NUMBER
else
  echo "======= Found RELEASE version ======="
fi

export MAVEN_OPTS="-Xmx1536m -Xms128m"
mvn deploy \
    -Pdeploy-sonarsource,release \
    -B -e -V
