#!/bin/sh
set -eu

#####################################################################
# help
#####################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
Usage   : ${0##*/} -u<repo url> -b<branch or hash> <entry script>
Options :

execute a task with <entry script> on <repo url> and <branch or hash>.
entry script must be specified with relative path to the top of the repo.

-u: specify the repository url.
-b: specify the branch or hash. master/main is used if nothing is specified.
USAGE
  exit 1
}

#####################################################################
# parameter
#####################################################################

opr=''
opt_u=''
opt_b=''

i=1
for arg in ${1+"$@"}
do
  case "$arg" in
    -h|--help|--version) print_usage_and_exit ;;
    -u*)                 opt_u=${arg#-u}      ;;
    -b*)                 opt_b=${arg#-b}      ;;
    *)
      if [ $i -eq $# ] && [ -z "$opr" ]; then
        opr=$arg
      else
        echo "${0##*/}: invalid args" 1>&2
        exit 1
      fi
      ;;
  esac

  i=$((i + 1))
done

if [ -z "${opt_u}" ] ; then
  echo "${0##*/}:ERROR: repository url must be spefied" 1>&2
  exit 1
fi

if [ -z "${opr}" ] ; then
  echo "${0##*/}:ERROR: entry script must be specified" 1>&2
  exit 1
fi

readonly REPO_URL="${opt_u}"
readonly ENTRY_SCRIPT="${opr}"

if [ -z "${opt_b}" ]; then
  BRANCH="${opt_b}"
else
  readonly BRANCH="${opt_b}"
fi

CUR_DIR=$(pwd)
readonly CUR_DIR
CLONE_DIR=$(basename "${REPO_URL}" '.git')
readonly CLONE_DIR

#####################################################################
# main routine
#####################################################################

# clean the previous
[ -d "${CLONE_DIR}" ] && rm -rf "${CLONE_DIR}"

# download the repository
if ! git clone "${REPO_URL}" >/dev/null; then
  echo "${0##*/}:ERROR: the repo is invalid <${REPO_URL}>" 1>&2
  exit 1
fi

# get into the target directory
trap 'cd ${CUR_DIR}' EXIT
if ! cd "${CLONE_DIR}"; then
  echo "${0##*/}:ERROR: cannot move to <${CLONE_DIR}>" 1>&2
  exit 1
fi

# select the default branch
if [ -z "${BRANCH}" ]; then
  if   git branch -r | grep -q '^ *origin/master$'; then
    readonly BRANCH='origin/master'
    echo "${0##*/}:INFO: hash is switched to <master>" 1>&2
  elif git branch -r | grep -q '^ *origin/main$'; then
    readonly BRANCH='origin/main'
    echo "${0##*/}:INFO: hash is switched to <main>" 1>&2
  else
    echo "${0##*/}:ERROR: some error for <${REPO_URL}>" 1>&2
    exit 1
  fi
fi

# checkout
if ! git checkout "${BRANCH}" >/dev/null; then
  echo "${0##*/}:ERROR: the branch/hash is invalid <${BRANCH}>" 1>&2
  exit 1
fi

# check the script
if [ ! -f "${ENTRY_SCRIPT}" ]; then
  echo "${0##*/}:ERROR: the entry not exist <${CLONE_DIR}/${ENTRY_SCRIPT}>" 1>&2
  exit 1
fi
if [ ! -x "${ENTRY_SCRIPT}" ]; then
  echo "${0##*/}:ERROR: the entry not executable <${CLONE_DIR}/${ENTRY_SCRIPT}>" 1>&2
  exit 1
fi

# execute the task
if ! ./"${ENTRY_SCRIPT}"; then
  echo "${0##*/}:ERROR: some execution error on <${CLONE_DIR}/${ENTRY_SCRIPT}>" 1>&2
  exit 1
fi
