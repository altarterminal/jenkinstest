#!/bin/sh
set -eu

#####################################################################
# help
#####################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
Usage   : ${0##*/} -u<repo url> <entry script>
Options : -b<branch or hash> -d<repo dir>

Execute a task with <entry script> on <repo url> and <branch or hash>.
Entry script must be specified with relative path to the top of the repo.

-u: Specify the repository url.
-b: Specify the branch or hash (default: origin/master or origin/main).
-d: Specify the directory in which the repositories are cloned (default: ./repo).
USAGE
  exit 1
}

#####################################################################
# parameter
#####################################################################

opr=''
opt_u=''
opt_b=''
opt_d='./repo'

i=1
for arg in ${1+"$@"}
do
  case "${arg}" in
    -h|--help|--version) print_usage_and_exit ;;
    -u*)                 opt_u="${arg#-u}"    ;;
    -b*)                 opt_b="${arg#-b}"    ;;
    -d*)                 opt_d="${arg#-d}"    ;;
    *)
      if [ $i -eq $# ] && [ -z "${opr}" ]; then
        opr="${arg}"
      else
        echo "ERROR:${0##*/}: invalid args" 1>&2
        exit 1
      fi
      ;;
  esac

  i=$((i + 1))
done

if [ -z "${opt_u}" ] ; then
  echo "ERROR:${0##*/}: repository url must be spefied" 1>&2
  exit 1
fi

if [ -z "${opr}" ] ; then
  echo "ERROR:${0##*/}: entry script must be specified" 1>&2
  exit 1
fi

if [ -e "${opt_d}" ]; then
  if [ ! -d "${opt_d}" ] || [ ! -w "${opt_d}" ]; then
    echo "ERROR:${0##*/}: invalid directory <${opt_d}>" 1>&2
    exit 1
  fi
else
  mkdir -p "${opt_d}"
  echo "INFO:${0##*/}: made the directory <${opt_d}>" 1>&2
fi

ENTRY_PATH="${opr}"
REPO_URL="${opt_u}"
BRANCH_RAW="${opt_b}"
REPO_DIR="${opt_d}"

#####################################################################
# setting
#####################################################################

CUR_DIR="$(pwd)"
CLONE_DIR=${REPO_DIR}/$(basename "${REPO_URL}" '.git')

ENTRY_DIR="$(dirname "${ENTRY_PATH}")"
ENTRY_SCRIPT="$(basename "${ENTRY_PATH}")"

#####################################################################
# prepare
#####################################################################

trap 'cd "${CUR_DIR}"' EXIT

#####################################################################
# main routine
#####################################################################

# clean the previous
[ -d "${CLONE_DIR}" ] && rm -rf "${CLONE_DIR}"

# download the repository
if ! git clone -q "${REPO_URL}" "${CLONE_DIR}"; then
  echo "ERROR:${0##*/}: git clone failed <${REPO_URL}>" 1>&2
  exit 1
fi

if ! cd "${CLONE_DIR}"; then
  echo "ERROR:${0##*/}: cannot move to <${CLONE_DIR}>" 1>&2
  exit 1
fi

# select the default branch
if [ -z "${BRANCH_RAW}" ]; then
  if   git branch -r | grep -q '^ *origin/master$'; then
    BRANCH='origin/master'
    echo "INFO:${0##*/}: hash is switched to <master>" 1>&2
  elif git branch -r | grep -q '^ *origin/main$'; then
    BRANCH='origin/main'
    echo "INFO:${0##*/}: hash is switched to <main>" 1>&2
  else
    echo "ERROR:${0##*/}: some error for <${REPO_URL}>" 1>&2
    exit 1
  fi
else
  BRANCH="${BRANCH_RAW}"
fi

# checkout
if ! git checkout -q "${BRANCH}"; then
  echo "ERROR:${0##*/}: git checkout failed <${BRANCH}>" 1>&2
  exit 1
fi

# change the current directory
if ! cd "${ENTRY_DIR}"; then
  echo "ERROR:${0##*/}: cannot move to <${ENTRY_DIR}>" 1>&2
  exit 1
fi

# check the script
if [ ! -f "${ENTRY_SCRIPT}" ]; then
  echo "ERROR:${0##*/}: the entry not exist <${CLONE_DIR}/${ENTRY_PATH}>" 1>&2
  exit 1
fi
if [ ! -x "${ENTRY_SCRIPT}" ]; then
  echo "ERROR:${0##*/}: the entry not executable <${CLONE_DIR}/${ENTRY_PATH}>" 1>&2
  exit 1
fi

# execute the task
if ! "./${ENTRY_SCRIPT}"; then
  echo "ERROR:${0##*/}: some execution error on <${CLONE_DIR}/${ENTRY_PATH}>" 1>&2
  exit 1
fi
