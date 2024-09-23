#!/bin/sh
set -u

#####################################################################
# help
#####################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
Usage   : ${0##*/} -u<url> -b<hash> <entry>
Options :

execute tasks by <entry> on <url> and <hash>

-u: specify the repository url
-b: specify the hash or branch
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
  HASH="${opt_b}"
else
  readonly HASH="${opt_b}"
fi

#####################################################################
# main routine
#####################################################################

CLONE_DIR=$(basename "${REPO_URL}" '.git')

[ -d "${CLONE_DIR}" ] && rm -rf "${CLONE_DIR}"

echo "${0##*/}:INFO: start clone" 1>&2
if ! git clone "${REPO_URL}" >/dev/null; then
  echo "${0##*/}:ERROR: the repo is invalid <${REPO_URL}>" 1>&2
  exit 1
fi

if [ -z "${HASH}" ]; then
  if git -C "${CLONE_DIR}" branch -r | grep -q '^ *origin/master$'; then
    readonly HASH='origin/master'
    echo "${0##*/}:INFO: hash is switched to master" 1>&2
  elif git -C "${CLONE_DIR}" branch -r | grep -q '^ *origin/main$'; then
    readonly HASH='origin/main'
    echo "${0##*/}:INFO: hash is switched to main" 1>&2
  else
    echo "${0##*/}:ERROR: some error for <${REPO_URL}>" 1>&2
    exit 1
  fi
fi

echo "${0##*/}:INFO: start checkout" 1>&2
if ! git -C "${CLONE_DIR}" checkout "${HASH}" >/dev/null; then
  echo "${0##*/}:ERROR: the hash is invalid <${HASH}>" 1>&2
  exit 1
fi

if [ ! -f "${CLONE_DIR}/${ENTRY_SCRIPT}" ]; then
  echo "${0##*/}:ERROR: the entory not exist <${CLONE_DIR}/${ENTRY_SCRIPT}>" 1>&2
  exit 1
fi
if [ ! -x "${CLONE_DIR}/${ENTRY_SCRIPT}" ]; then
  echo "${0##*/}:ERROR: the entory not executable <${CLONE_DIR}/${ENTRY_SCRIPT}>" 1>&2
  exit 1
fi

echo "${0##*/}:INFO: start execution" 1>&2
(
  if ! cd "${CLONE_DIR}"; then
    echo "${0##*/}:ERROR: cannot move to <${CLONE_DIR}>" 1>&2
    exit 1
  fi

  if ! ./"${ENTRY_SCRIPT}"; then
    echo "${0##*/}:ERROR: some execution error on <${CLONE_DIR}/${ENTRY_SCRIPT}>" 1>&2
    exit 1
  fi
)
