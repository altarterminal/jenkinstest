#!/bin/sh
set -eu

#####################################################################
# help
#####################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
Usage   : ${0##*/} -u<repo url> -b<branch or hash> <entry script>
Options : -d<repo dir>

execute a task with <entry script> on <repo url> and <branch or hash>.
entry script must be specified with relative path to the top of the repo.

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
      if [ $i -eq $# ] && [ -z "$opr" ]; then
        opr=$arg
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

readonly REPO_URL="${opt_u}"
readonly ENTRY_SCRIPT="${opr}"
readonly STORE_DIR="${opt_d}"

if [ -z "${opt_b}" ]; then
  BRANCH="${opt_b}"
else
  readonly BRANCH="${opt_b}"
fi

CUR_DIR=$(pwd)
readonly CUR_DIR
CLONE_DIR=${STORE_DIR}/$(basename "${REPO_URL}" '.git')
readonly CLONE_DIR

#####################################################################
# main routine
#####################################################################

# clean the previous
[ -d "${CLONE_DIR}" ] && rm -rf "${CLONE_DIR}"

# download the repository
if ! git clone "${REPO_URL}" "${CLONE_DIR}" >/dev/null; then
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
if ! git checkout "${BRANCH}" >/dev/null; then
  echo "ERROR:${0##*/}: the branch/hash is invalid <${BRANCH}>" 1>&2
  exit 1
fi

# check the script
if [ ! -f "${ENTRY_SCRIPT}" ]; then
  echo "ERROR:${0##*/}: the entry not exist <${CLONE_DIR}/${ENTRY_SCRIPT}>" 1>&2
  exit 1
fi
if [ ! -x "${ENTRY_SCRIPT}" ]; then
  echo "ERROR:${0##*/}: the entry not executable <${CLONE_DIR}/${ENTRY_SCRIPT}>" 1>&2
  exit 1
fi

# execute the task
if ! ./"${ENTRY_SCRIPT}"; then
  echo "ERROR:${0##*/}: some execution error on <${CLONE_DIR}/${ENTRY_SCRIPT}>" 1>&2
  exit 1
fi
