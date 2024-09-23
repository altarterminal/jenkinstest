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

specify the <exec list> (default: task.json).
cloned repositories are stored in 'test_store'.
USAGE
  exit 1
}

#####################################################################
# parameter
#####################################################################

opr='task.json'

i=1
for arg in ${1+"$@"}
do
  case "${arg}" in
    -h|--help|--version) print_usage_and_exit ;;
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

if ! type jq >/dev/null 2>&1; then
  echo "ERROR:${0##*/}: jq not installed" 1>&2
  exit 1
fi

if [ ! -f "${opr}" ] || [ ! -r "${opr}" ]; then
  echo "ERROR:${0##*/}: list cannot be accessed <${opr}>" 1>&2
  exit 1
fi

if ! jq . "${opr}" >/dev/null 2>&1; then
  echo "ERROR:${0##*/}: list is invalid <${opr}>" 1>&2
  exit 1
fi

readonly EXEC_LIST="${opr}"
readonly CUR_DIR="${0%/*}"
readonly EACH_EXEC="${CUR_DIR}/each_run.sh"
readonly STORE_DIR='test_store'

#####################################################################
# main routine
#####################################################################

LINE=$(jq -c '.[]' "${EXEC_LIST}" | tail -n 1)

URL=$(printf '%s\n' "${LINE}"    | jq -r '."url" // empty')
BRANCH=$(printf '%s\n' "${LINE}" | jq -r '."branch" // empty')
ENTRY=$(printf '%s\n' "${LINE}"  | jq -r '."entry" // empty')

if "${EACH_EXEC}" -d"${STORE_DIR}" -u"${URL}" -b"${BRANCH}" "${ENTRY}" 1>&2; then
  echo "INFO:${0##*/}: succeeded <${URL}:${BRANCH}:${ENTRY}>" 1>&2
else
  echo "ERROR:${0##*/}: failed <${URL}:${BRANCH}:${ENTRY}>" 1>&2
fi
