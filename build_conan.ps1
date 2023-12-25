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

get-command conan
if ($? -eq $false) {
  $env:VENV="./venv"
  if ( -not Test-Path -PathType Container -path $env:VENV ) {
    python -m venv $VENV
  }

  $VENV/Scripts/Activate.ps1
  pip install -r requirements.txt

  get-command conan
  if ($? -eq $false) {
    echo "No Conan on PATH after VirtualEnv install"
    exit 1
  }
}

$env:CONAN_DIR = "./build"
$env:BUILD_TYPE = "Release"
$env:OPTS = "-s build_type=$env:BUILD_TYPE --build=missing"
$env:Z3_SHARED = "-o z3/*:shared=True"
$env:SHARED_DIR = "$env:CONAN_DIR/shared"
$env:Z3_STATIC = "-o z3/*:shared=False"
$env:STATIC_DIR = "$env:CONAN_DIR/static"

$env:CONTENT_DIR = "$env:CONAN_DIR/content"

New-Item -Path $env:CONAN_DIR -ItemType "directory"
New-Item -Path $env:CONTENT_DIR -ItemType "directory"

$env:NO_COLOR="1"

if ( -not Test-Path env:\CONAN_HOME) {
  $env:CONAN_HOME="$env:PWD/.conan2"
  conan profile show -pr default
  $env:HAS_PROFILE=$?
  if ( $env:HAS_PROFILE -eq $false ) {
    conan profile detect
  }
}

if (Test-Path env:\SLM_BUILD_SHARED) {
  conan install . --deployer=full_deploy $env:Z3_SHARED $env:OPTS --output-folder $env:SHARED_DIR
  ,@(Get-ChildItem -Recurse -fi "libz3*" | Select FullName | findstr "libz3.*\.dll") | %{&cp $_ $env:CONTENT_DIR}
} elseif (Test-Path env:\SLM_BUILD_STATIC) {
  conan install . --deployer=full_deploy $env:Z3_STATIC $env:OPTS --output-folder $env:STATIC_DIR
  ,@(Get-ChildItem -Recurse -fi "libz3.a" | Select FullName | %{&cp $_ $env:CONTENT_DIR}
  ,@(Get-ChildItem -Recurse -fi "z3.h" | Select FullName | %{&Split-Path -parent $_} |  %{&cp -Recurse $_ $env:CONTENT_DIR}
} else {
  echo "Invalid Build Type Instruction - Neither 'SLM_BUILD_SHARED' or 'SLM_BUILD_STATIC' were defined."
  exit 1
}

echo "LibZ3: Build Complete"

