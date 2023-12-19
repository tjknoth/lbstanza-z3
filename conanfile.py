# Z3 Shared/Static Dependency Script
#  This file contains the conan configurations
#  for building the Z3 library dependency needed
#  for this wrapper to work. The idea is that
#  conan handles all the platform specific build
#  setup and then we cherry pick the static or
#  dynamic library files for stanza to link against.

import sys
V = sys.version_info
if V[0] < 3:
  raise RuntimeError("Invalid Python Version - This script expects at least Python 3")

import os
import platform
from conan import ConanFile
from conan.tools.files import copy


class Z3Recipe(ConanFile):
  """ Conan2 Recipe to create a deployment of the Z3 library.
  The goal isn't a package - but to generate the *.so/*.dll/etc that
  is needed for the user's current platform.
  """
  name = "stanza-z3"
  package_type = "application"

  # Optional metadata
  author = "Carl Allendorph (callendorph@gmail.com)"
  url = "https://github.com/callendorph/lbstanza-z3"
  description = "Stanza Z3 Wrapper Builder"
  topics = ("stanza", "z3", "library management", "package management")

  # Binary configuration
  settings = "os", "arch", "compiler", "build_type"
  generators = "CMakeToolchain", "CMakeDeps"

  # Use `-o shared=True` on the commandline to
  #  build the dynamic version
  options = {"shared": [True, False], "fPIC": [True, False]}
  default_options = {"shared": False, "fPIC": True}

  implements = ["auto_shared_fpic"]

  def requirements(self):
    self.requires("z3/4.12.2")

