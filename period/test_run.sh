#!/bin/sh
set -eu

#####################################################################
# help
#####################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
Usage   : ${0##*/} <exec list>
Options :

execute a last task on <exec list>.
This is intended to test when adding a task.
USAGE
  exit 1
}

#####################################################################
# parameter
#####################################################################

opr=''

i=1
for arg in ${1+"$@"}
do
  case "$arg" in
    -h|--help|--version) print_usage_and_exit ;;
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

if ! type jq >/dev/null 2>&1; then
  echo "${0##*/}:ERROR: jq not installed" 1>&2
  exit 1
fi

if [ ! -f "${opr}" ] || [ ! -r "${opr}" ]; then
  echo "${0##*/}:ERROR: list cannot be accessed <${opr}>" 1>&2
  exit 1
fi

if ! jq . "${opr}" >/dev/null 2>&1; then
  echo "${0##*/}:ERROR: list is invalid <${opr}>" 1>&2
  exit 1
fi

readonly EXEC_LIST="${opr}"
readonly CUR_DIR="${0%/*}"
readonly EACH_EXEC="${CUR_DIR}/each_run.sh"

#####################################################################
# main routine
#####################################################################

LINE=$(jq -c '.[]' "${EXEC_LIST}" | tail -n 1)

URL=$(printf '%s\n' "${LINE}"   | jq -r '."url"')
BRANCH=$(printf '%s\n' "${LINE}"  | jq -r '."branch"')
ENTRY=$(printf '%s\n' "${LINE}" | jq -r '."entry"')

if "${EACH_EXEC}" -u"${URL}" -b"${BRANCH}" "${ENTRY}" 1>&2; then
  echo "${0##*/}:INFO: succeeded <${URL}:${BRANCH}:${ENTRY}>" 1>&2
else
  echo "${0##*/}:ERROR: failed <${URL}:${BRANCH}:${ENTRY}>" 1>&2
fi
