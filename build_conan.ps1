#
#  Conan Build for Windows (Powershell)
#  This script assumes that you have:
#   - python or python3 defined on your path
#   - VirtualEnv (ie, you can run `python3 -m venv venv` and get a proper virtual env.)
#
#  This script is intended to be run from the Stanza Library Manager (slm) to
#  configure the libz3 dependency before running the stanza compiler.
#
#  This script expects one of these two environment variables to be set:
#  SLM_BUILD_SHARED = If set, then a shared library (*.dll) will
#    be generated and put in ${CONTENT_DIR}
#  SLM_BUILD_STATIC = If set, then a static library (libz3.a) will be generated
#    and put in ${CONTENT_DIR}

python build_conan.py
