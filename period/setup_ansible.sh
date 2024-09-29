#!/bin/sh
set -eu

#####################################################################
# help
#####################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
Usage   : ${0##*/} <env path>
Options : -f

setup python's venv on <env path>.
ansible will be installed on the venv.

-f: enable the force install (delete the existing directory).
USAGE
  exit 1
}

#####################################################################
# parameter
#####################################################################

opr=''
opt_f='no'

i=1
for arg in ${1+"$@"}
do
  case "${arg}" in
    -h|--help|--version) print_usage_and_exit ;;
    -f)                  opt_f='yes'          ;;
    *)
      if [ $i -eq $# ]; then
        opr=${arg}
      else
        echo "ERROR:${0##*/}: invalid args" 1>&2
        exit 1
      fi
      ;;
  esac

  i=$((i + 1))
done

if type ansible >/dev/null 2>&1; then
  echo "INFO:${0##*/}: ansible has already been installed" 1>&2
  exit 0
fi

if ! type python3 >/dev/null 2>&1; then
  echo "ERROR:${0##*/}: python3 not installed" 1>&2
  exit 1
fi

if [ -z "${opr}" ]; then
  echo "ERROR:${0##*/}: env path must be specified" 1>&2
  exit 1
fi

readonly ENV_PATH="${opr}"
readonly IS_FORCE="${opt_f}"

#####################################################################
# main routine
#####################################################################

# check the existing directory
if [ "${IS_FORCE}" = 'yes' ]; then
  rm -rf "${ENV_PATH}"
  echo "INFO:${0##*/}: deleted the old directory <${ENV_PATH}>" 1>&2
fi
if [ -d "${ENV_PATH}" ]; then
  echo "ERROR:${0##*/}: there is the existing directory <${ENV_PATH}>" 1>&2
  exit 1
fi

# make an environment
mkdir -p "$(dirname "${ENV_PATH}")"
python3 -m venv "${ENV_PATH}"

# install the ansible
. "${ENV_PATH}/bin/activate"
pip install ansible

# check the ansible has been installed
if ! type ansible >/dev/null 2>&1; then
  echo "ERROR:${0##*/}: ansible has not been installed for some reason" 1>&2
  exit 1
fi
