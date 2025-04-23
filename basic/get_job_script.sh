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

if [ "${opr}" = '' ]; then
  echo "ERROR:${0##*/}: job name must be specified specified" 1>&2
  exit 1
fi

JOB_NAME="${opr}"

#####################################################################
# setting
#####################################################################

THIS_DIR="$(dirname "$0")"

BASE_TOOL="${THIS_DIR}/get_job_config.sh"

SCRIPT_PATH='."flow-definition"."definition"."script"'

#####################################################################
# check
#####################################################################

if [ ! -f "${BASE_TOOL}" ] || [ ! -x "${BASE_TOOL}" ]; then
  echo "ERROR:${0##*/}: required tool not found <${BASE_TOOL}>" 1>&2
  exit 1
fi

#####################################################################
# main routine
#####################################################################

"${BASE_TOOL}" "${JOB_NAME}"                                        |

xq -r "${SCRIPT_PATH}"
