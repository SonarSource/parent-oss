#!/bin/bash

set -euo pipefail

mvn verify -B -V -e
