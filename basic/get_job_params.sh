#!/bin/sh
set -eu

#####################################################################
# help
#####################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
Usage   : ${0##*/} <job name>
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

if [ "${opr}" = '' ]; then
  echo "ERROR:${0##*/}: job name must be specified specified" 1>&2
  exit 1
else
  :
fi

JOB_NAME="${opr}"

#####################################################################
# setting
#####################################################################

THIS_DIR="$(dirname "$0")"

BASE_TOOL="${THIS_DIR}/get_job_config.sh"

PARAM_PATH='."flow-definition"."properties"."hudson.model.ParametersDefinitionProperty"."parameterDefinitions"'

#####################################################################
# main routine
#####################################################################

"${BASE_TOOL}" "${JOB_NAME}"                                        |

xq -r "${PARAM_PATH}"                                               |

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
