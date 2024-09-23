#!/bin/sh
set -u

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
readonly CUR_DIR="$(dirname "$0")"

#####################################################################
# main routine
#####################################################################

jq -c '.[]' "${EXEC_LIST}"                                          |

while read -r line;
do
  url=$(printf '%s\n' "${line}"   | jq -r '."url"')
  hash=$(printf '%s\n' "${line}"  | jq -r '."hash"')
  entry=$(printf '%s\n' "${line}" | jq -r '."entry"')

  echo "=====================================================" 1>&2;
  echo "URL   = ${url}"   1>&2
  echo "HASH  = ${hash}"  1>&2
  echo "ENTRY = ${entry}" 1>&2
  echo "=====================================================" 1>&2;

  if "${CUR_DIR}/each_run.sh" -u"${url}" -b"${hash}" "${entry}" 1>&2; then
    echo "OK:${url}:${hash}:${entry}"
  else
    echo "${0##*/}:ERROR: failed <${url}:${hash}:${entry}>" 1>&2
    echo "NG:${url}:${hash}:${entry}"
  fi
done                                                                 |

awk '
{ 
  buf[NR] = $0;
}

END {
  print "===========================================" >"/dev/stderr";
  print "Summary" >"/dev/stderr";

  for (i = 1; i <= NR; i++) {
    print i, buf[i] >"/dev/stderr";
  }

  print "===========================================" >"/dev/stderr";
}
'
