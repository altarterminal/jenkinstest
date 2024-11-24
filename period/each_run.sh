#!/bin/sh
set -eu

#####################################################################
# help
#####################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
Usage   : ${0##*/} -u<repo url> -b<branch or hash> <entry script>
Options : -d<repo dir>

Execute a task with <entry script> on <repo url> and <branch or hash>.
Entry script must be specified with relative path to the top of the repo.

-u: specify the repository url.
-b: specify the branch or hash. master/main is used if nothing is specified.
-d: specify the directory in which the repositories are cloned (default: .)
USAGE
  exit 1
}

#####################################################################
# parameter
#####################################################################

opr=''
opt_u=''
opt_b=''
opt_d='.'

i=1
for arg in ${1+"$@"}
do
  case "${arg}" in
    -h|--help|--version) print_usage_and_exit ;;
    -u*)                 opt_u=${arg#-u}      ;;
    -b*)                 opt_b=${arg#-b}      ;;
    -d*)                 opt_d=${arg#-d}      ;;
    *)
      if [ $i -eq $# ] && [ -z "${opr}" ]; then
        opr=${arg}
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

readonly ENTRY_PATH="${opr}"
readonly REPO_URL="${opt_u}"
readonly BRANCH="${opt_b}"
readonly CLONE_TOP_DIR="${opt_d}"

if [ -n "${BRANCH}" ]; then
  readonly BRANCH
fi

CUR_DIR=$(pwd)
CLONE_DIR=${CLONE_TOP_DIR}/$(basename "${REPO_URL}" '.git')
EXEC_DIR="${ENTRY_PATH%/*}"
ENTRY_SCRIPT="${ENTRY_PATH##*/}"

readonly CUR_DIR
readonly CLONE_DIR
readonly EXEC_DIR
readonly ENTRY_SCRIPT

#####################################################################
# main routine
#####################################################################

# clean the previous
[ -d "${CLONE_DIR}" ] && rm -rf "${CLONE_DIR}"

# download the repository
if ! git clone -q "${REPO_URL}" "${CLONE_DIR}"; then
  echo "ERROR:${0##*/}: the repo is invalid <${REPO_URL}>" 1>&2
  exit 1
fi

# get into the target directory
trap 'cd "${CUR_DIR}"' EXIT
if ! cd "${CLONE_DIR}"; then
  echo "ERROR:${0##*/}: cannot move to <${CLONE_DIR}>" 1>&2
  exit 1
fi

# select the default branch
if [ -z "${BRANCH}" ]; then
  if   git branch -r | grep -q '^ *origin/master$'; then
    readonly BRANCH='origin/master'
    echo "INFO:${0##*/}: hash is switched to <master>" 1>&2
  elif git branch -r | grep -q '^ *origin/main$'; then
    readonly BRANCH='origin/main'
    echo "INFO:${0##*/}: hash is switched to <main>" 1>&2
  else
    echo "ERROR:${0##*/}: some error for <${REPO_URL}>" 1>&2
    exit 1
  fi
fi

# checkout
if ! git checkout -q "${BRANCH}"; then
  echo "ERROR:${0##*/}: the branch/hash is invalid <${BRANCH}>" 1>&2
  exit 1
fi

# change the current directory
if ! cd "${EXEC_DIR}"; then
  echo "ERROR:${0##*/}: cannot move to <${EXEC_DIR}>" 1>&2
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
