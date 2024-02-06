#!/bin/bash

set -Eeuo pipefail

# Required env var inputs
#echo "            BRANCH:" "${BRANCH:?err}"

# Defaulted env var inputs - can override if necessary
echo "                CONAN: ${CONAN:=conan}"
echo "           CONAN_HOME: ${CONAN_HOME:=$PWD/.conan2}"
export CONAN_HOME
echo "           OUTPUT_DIR: ${OUTPUT_DIR:=$PWD/build}"
echo "     SLM_BUILD_SHARED: ${SLM_BUILD_SHARED:=0}"
echo "     SLM_BUILD_STATIC: ${SLM_BUILD_STATIC:=1}"
echo "  CONAN_BUILD_PROFILE: ${CONAN_BUILD_PROFILE:=default}"
echo "   CONAN_HOST_PROFILE: ${CONAN_HOST_PROFILE:=default}"

set +u  # temporarily disable unset var checking
if [ "${VIRTUAL_ENV}" == "" ] ; then
    echo "       VIRTUAL_ENV: (unset)"
    echo
    echo "ERROR: This script is intended to run in a pre-existing python virtual environment"
    echo "       Please activate a python venv and run this script again"
    echo
    exit -1
fi
set -u
echo "       VIRTUAL_ENV: ${VIRTUAL_ENV}"

pip install -r requirements.txt

# support SLM_BUILD_SHARED values of "0", "1", "true", and "false"
# only values of "1" or "true" are recognized as enabling shared libraries
SHARED="False"
set +u  # temporarily disable unset var checking
if [[ "${SLM_BUILD_SHARED}" == "1" || "${SLM_BUILD_SHARED,,}" == "true" ]] ; then
    SHARED="True"
fi
set -u

# make sure conan default profile exists if CONAN_BUILD_PROFILE or CONAN_HOST_PROFILE are default
if [[ ( "${CONAN_BUILD_PROFILE}" == "default" || "${CONAN_HOST_PROFILE}" == "default" ) && ! -e ${CONAN_HOME}/profiles/default ]] ; then
    echo "Detecting default build profile for conan in \"${CONAN_HOME}/profiles/default\""
    ${CONAN} profile detect
fi

mkdir -p "${OUTPUT_DIR}"
${CONAN} config install ./conan-config  # installs custom generator and deployer into $CONAN_HOME

CONAN_LOG="${OUTPUT_DIR}/build_conan.log"
echo
echo "Building conan dependencies.  This may take a while."
echo "Check logfile \"${CONAN_LOG}\" for progress."
echo
set +e  # don't exit on error so we can get the exit status
${CONAN} install . \
         -pr:b ${CONAN_BUILD_PROFILE} \
         -pr:h ${CONAN_HOST_PROFILE} \
         -o shared=${SHARED} \
         --deployer=lbstanza_deployer \
         --generator=LBStanzaGenerator \
         -vtrace \
         --output-folder "${OUTPUT_DIR}" \
         --build missing \
         >${CONAN_LOG} 2>&1
STATUS=$?
set -e
if [ ${STATUS} -ne 0 ] ; then
    tail -20 ${CONAN_LOG}
    echo "conan dependencies failed!"
else
    echo "done."
fi
