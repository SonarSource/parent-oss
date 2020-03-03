#!/bin/bash

set -euo pipefail

function installTravisTools {
  mkdir -p ~/.local
  curl -sSL https://github.com/SonarSource/travis-utils/tarball/v57 | tar zx --strip-components 1 -C ~/.local
  source ~/.local/bin/install
}

# configures the global variables used by this script
function setupEnvironment {
  installTravisTools

  export GITHUB_REPO=${TRAVIS_REPO_SLUG} # CIRRUS_REPO_FULL_NAME
  SPLIT_NAME=(${TRAVIS_REPO_SLUG//\// })
  export PROJECT_NAME=${SPLIT_NAME[1]}

  export BUILD_NUMBER=${TRAVIS_BUILD_NUMBER} # cirrusBuildNumber() in cirrus-env script...
  export PULL_REQUEST_NUMBER=${TRAVIS_PULL_REQUEST} # ${CIRRUS_PR:-false}
  export PIPELINE_ID=${TRAVIS_BUILD_ID} # CIRRUS_BUILD_ID

  export ARTIFACT_URL="$ARTIFACTORY_URL/webapp/#/builds/$PROJECT_NAME/$BUILD_NUMBER"

  if [ -z $TRAVIS_PULL_REQUEST_SHA ]; then
    export GIT_SHA1=${TRAVIS_COMMIT} # $CIRRUS_CHANGE_IN_REPO
    export GITHUB_BRANCH_NAME=${TRAVIS_BRANCH} #$CIRRUS_BRANCH
    export STAGE_TYPE="branch"
    export STAGE_ID=${GITHUB_BRANCH_NAME}
  else
    export GIT_SHA1=${TRAVIS_PULL_REQUEST_SHA}
    export GITHUB_BRANCH_NAME=${TRAVIS_PULL_REQUEST_BRANCH}
    export STAGE_TYPE="pr_number"
    export STAGE_ID=${PULL_REQUEST_NUMBER}
  fi

  echo "======= SHA1 is ${GIT_SHA1} on branch '${GITHUB_BRANCH_NAME}'. Burgr stage '${STAGE_TYPE} with stage ID '${STAGE_ID} ======="

  # get current version from pom
  export CURRENT_VERSION=`maven_expression "project.version"`
  export ARTIFACTID=`maven_expression "project.artifactId"`

  if [[ $CURRENT_VERSION =~ "-SNAPSHOT" ]]; then
    echo "======= Found SNAPSHOT version ======="
    # Do not deploy a SNAPSHOT version but the release version related to this build
    . set_maven_build_version $TRAVIS_BUILD_NUMBER
  else
    export PROJECT_VERSION=`maven_expression "project.version"`
    echo "======= Found RELEASE version ======="
  fi
}

# Burgr notifications

function callBurgr {
  HTTP_CODE=$(curl --silent --output out.txt --write-out %{http_code} \
    -d @$1 \
    -H "Content-type: application/json" \
    -X POST \
    -u"${BURGRX_USER}:${BURGRX_PASSWORD}" \
    $2)

  echo "The payload sent to burgr was:"
  cat $1
  if [[ "$HTTP_CODE" != "200" ]] && [[ "$HTTP_CODE" != "201" ]]; then
    echo ""
    echo "Burgr did not ACK notification ($HTTP_CODE)"
    echo "ERROR:"
    cat out.txt
    echo ""
    exit -1
  else
    echo ""
    echo "Burgr ACKed notification for call to $2"
    echo ""
  fi
}

function notifyBurgr {
  # the Burgr stage type can be 'branch' or 'pr_number'
  BURGR_FILE=burgr
  cat > $BURGR_FILE <<EOF1 
  {
    "repository": "$GITHUB_REPO",
    "pipeline": "$PIPELINE_ID",
    "name": "$1",
    "system": "travis",
    "type": "$2",
    "number": "$PIPELINE_ID",
    "$STAGE_TYPE": "$STAGE_ID",
    "sha1": "$GIT_SHA1",
    "url":"$3",
    "status": "passed",
    "started_at": "$4",
    "finished_at": "$5"
  }
EOF1

  BURGR_STAGE_URL="$BURGRX_URL/api/stage"
  callBurgr $BURGR_FILE $BURGR_STAGE_URL
}

function buildAndPromote {
  BUILD_START_DATETIME=`date --utc +%FT%TZ`

  export MAVEN_OPTS="-Xmx1536m -Xms128m"
  mvn deploy \
    -Pdeploy-sonarsource,release \
    -B -e -V

  # Google Cloud Function to do the promotion
  GCF_PROMOTE_URL="$PROMOTE_URL/$GITHUB_REPO/$GITHUB_BRANCH_NAME/$BUILD_NUMBER/$PULL_REQUEST_NUMBER"
  echo "GCF_PROMOTE_URL: $GCF_PROMOTE_URL"

  curl -sfSL -H "Authorization: Bearer $GCF_ACCESS_TOKEN" "$GCF_PROMOTE_URL"

  # Notify Burgr

  BUILD_END_DATETIME=`date --utc +%FT%TZ`
  # $TRAVIS_JOB_WEB_URL is defined by Travis

  notifyBurgr "build" "promote" "$TRAVIS_JOB_WEB_URL" "$BUILD_START_DATETIME" "$BUILD_END_DATETIME"
  notifyBurgr "artifacts" "promotion" "$ARTIFACT_URL" "$BUILD_END_DATETIME" "$BUILD_END_DATETIME"

  BURGR_VERSION_FILE=burgr_version
  cat > $BURGR_VERSION_FILE <<EOF1
  {
    "version": "$PROJECT_VERSION",
    "build": "$BUILD_NUMBER",
    "url":  "$ARTIFACT_URL"
  }
EOF1

  BURGR_VERSION_URL="$BURGRX_URL/api/promote/$GITHUB_REPO/$PIPELINE_ID"

  callBurgr $BURGR_VERSION_FILE $BURGR_VERSION_URL
}

function doRelease  {
  if [[ $STAGE_ID != "master" ]] || [[ $CURRENT_VERSION =~ "-SNAPSHOT" ]]; then
    echo "This is a dev build or is not on master, not releasing."
    exit 0
  else
    echo "About to release ${ARTIFACTID}."
  fi

  # from the old Jenkins promote-release.sh script

  STATUS='released'
  OP_DATE=$(date +%Y%m%d%H%M%S)
  TARGET_REPOSITORY=$1
  DATA_JSON="{ \"status\": \"$STATUS\", \"properties\": { \"release\" : [ \"$OP_DATE\" ]}, \"targetRepo\": \"$TARGET_REPOSITORY\", \"copy\": false }"

  RELEASE_URL="$ARTIFACTORY_URL/api/build/promote/$PROJECT_NAME/$BUILD_NUMBER"
  echo "RELEASE_URL: $RELEASE_URL"
  echo "DATA_JSON: $DATA_JSON"

  HTTP_CODE=$(curl -s --output release-out.txt -w %{http_code} \
    -H "X-JFrog-Art-Api:${ARTIFACTORY_API_KEY}" \
    -H "Content-type: application/json" \
    -X POST \
    "$RELEASE_URL" \
    -d "$DATA_JSON")

  if [ "$HTTP_CODE" != "200" ]; then
    echo "Cannot release build ${PROJECT_NAME} #${BUILD_NUMBER}: ($HTTP_CODE)"
    echo ""
    echo "ERROR:"
    cat release-out.txt
    echo ""
    exit 1
  else
    echo "Build ${PROJECT_NAME} #${BUILD_NUMBER} released to ${TARGET_REPOSITORY}"
  fi

  # Notify Burgr

  RELEASE_DATETIME=`date --utc +%FT%TZ`
  notifyBurgr "release" "release" "$ARTIFACT_URL" "$RELEASE_DATETIME" "$RELEASE_DATETIME"
}

setupEnvironment

# Build, promote, release if necessary
buildAndPromote

doRelease "sonarsource-public-releases"
