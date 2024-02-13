import os
import sys
import subprocess


if __name__ == '__main__' :

  # Defaulted env var inputs - can override if necessary
  CONAN = os.environ.get('CONAN', 'conan')
  CONAN_HOME = os.environ.get('CONAN_HOME', f'{os.getcwd()}/.conan2')
  os.environ['CONAN_HOME'] = CONAN_HOME # export it
  OUTPUT_DIR = os.environ.get('OUTPUT_DIR', f'{os.getcwd()}/build')
  CONAN_BUILD_PROFILE = os.environ.get('CONAN_BUILD_PROFILE', 'default')
  CONAN_HOST_PROFILE = os.environ.get('CONAN_HOST_PROFILE', 'default')
  SLM_BUILD_DYNAMIC_LIB = os.environ.get('SLM_BUILD_DYNAMIC_LIB', 'False').capitalize()

  def no_conan_profile () :
    return (CONAN_BUILD_PROFILE == 'default' or CONAN_HOST_PROFILE == 'default') and not (os.path.exists(os.path.join(CONAN_HOME, 'profiles', 'default')))

  if sys.prefix == sys.base_prefix :
    print('ERROR: This script is intended to run in a pre-existing python virtual environment')
    print('       Please activate a python venv and run this script again')
    sys.exit(-1)

  print(f'                CONAN: {CONAN}')
  print(f'           CONAN_HOME: {CONAN_HOME}')
  print(f'           OUTPUT_DIR: {OUTPUT_DIR}')
  print(f'  CONAN_BUILD_PROFILE: {CONAN_BUILD_PROFILE}')
  print(f'   CONAN_HOST_PROFILE: {CONAN_HOST_PROFILE}')
  print(f'SLM_BUILD_DYNAMIC_LIB: {SLM_BUILD_DYNAMIC_LIB}')
  print(f"          VIRTUAL_ENV: {os.environ.get('VIRTUAL_ENV')}")

  # TODO: is there something smarter to do?
  subprocess.run([sys.executable, '-m', 'pip', 'install', '-r' 'requirements.txt'],
                  stdout=subprocess.DEVNULL,
                  stderr=subprocess.STDOUT)

  # make sure conan default profile exists if CONAN_BUILD_PROFILE or CONAN_HOST_PROFILE are default
  if no_conan_profile() :
      print(f'Detecting default build profile for conan in \'{CONAN_HOME}/profiles/default\'')
      subprocess.run([CONAN, 'profile', 'detect'],
                      stdout=subprocess.DEVNULL,
                      stderr=subprocess.STDOUT)

  # might want something more robust here
  try:
    os.mkdir(OUTPUT_DIR)
  except OSError as error :
    pass # do nothing

  # TODO: check for failure
  # might want to log this?
  print([CONAN, 'config', 'install', f'{os.getcwd()}/conan-config'])
  subprocess.run([CONAN, 'config', 'install', f'{os.getcwd()}/conan-config'],
                  stdout=subprocess.DEVNULL,
                  stderr=subprocess.STDOUT)

  CONAN_LOG = f'{OUTPUT_DIR}/build_conan.log'
  print()
  print('Building conan dependencies.  This may take a while.')
  print(f'Check logfile \'{CONAN_LOG}\' for progress.')
  print()

  with open(CONAN_LOG, 'w+') as logfile :
    result = subprocess.run([CONAN, 'install', '.',
      '-pr:b', CONAN_BUILD_PROFILE,
      '-pr:h', CONAN_HOST_PROFILE,
      '-o', f'shared={SLM_BUILD_DYNAMIC_LIB}',
      '--deployer=lbstanza_deployer',
      '--generator=LBStanzaGenerator',
      '-vtrace',
      '--output-folder', OUTPUT_DIR,
      '--build', 'missing'
      ], stdout = logfile, stderr = subprocess.STDOUT)

    if result.returncode != 0 :
      tail = logfile.readlines()[-20:]
      print(''.join(tail))
      print('conan dependencies failed')
    else :
      print('done')