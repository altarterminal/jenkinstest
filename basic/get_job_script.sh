#!/bin/sh
set -eu

#####################################################################
# help
#####################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
Usage   : ${0##*/} <job name>
Options : -k<access key>

Get parameters of the job.

-k: Specify the access key for jenkins master (default: ${HOME}/.ssh/id_rsa).
USAGE
  exit 1
}

#####################################################################
# parameter
#####################################################################

opr=''
opt_k="${HOME}/.ssh/id_rsa"

i=1
for arg in ${1+"$@"}
do
  case "${arg}" in
    -h|--help|--version) print_usage_and_exit ;;
    -k*)                 opt_k="${arg#-k}"    ;;
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
ACCESS_KEY="${opt_k}"

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

"${BASE_TOOL}" -k"${ACCESS_KEY}" "${JOB_NAME}"                      |

xq -r "${SCRIPT_PATH}"
