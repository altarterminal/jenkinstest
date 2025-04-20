#!/bin/sh
set -eu

#####################################################################
# help
#####################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
Usage   : ${0##*/} <job definition>
Options : 

Get parameters of the job.
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
  case "${arg}" in
    -h|--help|--version) print_usage_and_exit ;;
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

if ! type xq >/dev/null 2>&1; then
  echo "ERROR:${0##*/}: xq command not found" 1>&2
  exit 1
fi

if ! type jq >/dev/null 2>&1; then
  echo "ERROR:${0##*/}: jq command not found" 1>&2
  exit 1
fi

if   [ "${opr}" = '' ] || [ "${opr}" = '-' ]; then
  opr='-'
elif [ ! -f "${opr}" ] || [ ! -r "${opr}" ]; then
  echo "ERROR:${0##*/}: invalid file specified" 1>&2
  exit 1
else
  :
fi

JOB_FILE="${opr}"

#####################################################################
# setting
#####################################################################

SCRIPT_PATH='."flow-definition"."properties"."hudson.model.ParametersDefinitionProperty"."parameterDefinitions"'

#####################################################################
# main routine
#####################################################################

cat "${JOB_FILE}"                                                   |

xq -r "${SCRIPT_PATH}"                                              |

jq 'to_entries'                                                     |
jq -c '.[]'                                                         |

while read -r line
do
  type=$(printf '%s\n' "${line}" | jq '.key')
  name=$(printf '%s\n' "${line}" | jq '.value.name')
  default=$(printf '%s\n' "${line}" | jq '.value.defaultValue // ""')
  description=$(printf '%s\n' "${line}" | jq '.value.description // ""')

  printf '{"name":%s,"type":%s,"default":%s,"description":%s}\n'    \
    "${name}" "${type}" "${default}" "${description}"
done                                                                |

jq -s
