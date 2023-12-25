#!/bin/bash
#
#  Conan Build for Linux / OS-X
#  This script assumes that you have:
#   - python or python3 defined on your path
#   - VirtualEnv (ie, you can run `python3 -m venv venv` and get a proper virtual env.)
#
#  This script is intended to be run from the Stanza Library Manager (slm) to
#  configure the libz3 dependency before running the stanza compiler.
#
#  This script expects one of these two environment variables to be set:
#  SLM_BUILD_SHARED = If set, then a shared library (*.so or *.dylib) will
#    be generated and put in ${CONTENT_DIR}
#  SLM_BUILD_STATIC = If set, then a static library (libz3.a) will be generated
#    and put in ${CONTENT_DIR}
#
#

set -eou pipefail

set +e
which conan
CONAN_STATUS=$?
set -e

if [ $CONAN_STATUS -ne 0 ] ; then
  VENV=./venv
  if [ ! -d $VENV ]; then
    echo "Creating Virtual Environment"
    python -m venv $VENV
  fi
  echo "Activating Virtual Environment"
  source $VENV/bin/activate
  echo "Installing Conan + Deps ..."
  pip install -r requirements.txt

  if ! which conan ; then
    echo "No Conan On Path after VirtualEnv Install"
    exit 1
  fi
  echo "Conan READY"
fi

CONAN_DIR="./build"
BUILD_TYPE="Release"
OPTS="-s build_type=${BUILD_TYPE} --build=missing"
Z3_SHARED="-o z3/*:shared=True"
SHARED_DIR="${CONAN_DIR}/shared"
Z3_STATIC="-o z3/*:shared=False"
STATIC_DIR="${CONAN_DIR}/static"

CONTENT_DIR=${CONAN_DIR}/content

# Setup
mkdir -p ${CONAN_DIR}
mkdir -p ${CONTENT_DIR}

# Disable Color output in Conan
#  makes for easier logs
export NO_COLOR=1

# Check for CONAN_HOME
if [ -z ${CONAN_HOME:-} ] ; then
  export CONAN_HOME=${PWD}/.conan2
  # Attempt to initialize a profile here so that
  #   we don't run into any issues with conan failing to build.
  set +e
  conan profile show -pr default
  HAS_PROFILE=$?
  set -e
  if [ $HAS_PROFILE -ne 0 ] ; then
    conan profile detect
  fi
fi

if [ ! -z ${SLM_BUILD_SHARED:-} ]; then
  echo "LibZ3: Building Shared Library"
	conan install . --deployer=full_deploy ${Z3_SHARED} ${OPTS} --output-folder ${SHARED_DIR}
	find ${SHARED_DIR} | grep -sE "libz3.*\.(so|dll|dylib)" | xargs -I% cp -v -a % ${CONTENT_DIR}
elif [ ! -z ${SLM_BUILD_STATIC:-} ]; then
  echo "LibZ3: Building Static Library"
	conan install . --deployer=full_deploy ${Z3_STATIC} ${OPTS} --output-folder ${STATIC_DIR}
	find ${STATIC_DIR} | grep -sE "libz3\.a" | xargs -I% cp -v % ${CONTENT_DIR}
	find ${STATIC_DIR} -name "z3.h" | xargs -I% dirname %  | xargs | xargs -I% cp -r % ${CONTENT_DIR}
else
  echo "Invalid Build Type Instruction - Neither 'SLM_BUILD_SHARED' or 'SLM_BUILD_STATIC' were defined."
  exit 1
fi

echo "LibZ3: Build Complete"
