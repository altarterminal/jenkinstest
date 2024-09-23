#!/bin/sh
set -eu

#####################################################################
# help
#####################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
Usage   : ${0##*/} <exec list>
Options :

execute tasks on <exec list>
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

jq -c '.[]' "${EXEC_LIST}"                                          |

while read -r line;
do
  url=$(printf '%s\n' "${line}"    | jq -r '."url"')
  branch=$(printf '%s\n' "${line}" | jq -r '."branch"')
  entry=$(printf '%s\n' "${line}"  | jq -r '."entry"')

  {
    echo "=========================================================="
    echo "URL    = ${url}"
    echo "BRANCH = ${branch}"
    echo "ENTRY  = ${entry}"
    echo "=========================================================="
  } 1>&2

  if "${EACH_EXEC}" -u"${url}" -b"${branch}" "${entry}" 1>&2; then
    echo "OK:${url}:${branch}:${entry}"
    echo "${0##*/}:INFO: succeeded <${url}:${branch}:${entry}>" 1>&2
  else
    echo "NG:${url}:${branch}:${entry}"
    echo "${0##*/}:ERROR: failed <${url}:${branch}:${entry}>" 1>&2
  fi
done                                                                |

awk '
{
  buf[NR] = $0;
}

END {
  print "==========================================================="
  print "Summary"
  for (i = 1; i <= NR; i++) { print i, buf[i]; }
  print "==========================================================="
}
' 1>&2
