#!/bin/sh
set -eu

#####################################################################
# help
#####################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
Usage   : ${0##*/} <job name>
Options : -k<access key>

Get config of the job.

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

if [ "${opr}" = '' ]; then
  echo "ERROR:${0##*/}: job name must be specified" 1>&2
  exit 1
fi

if [ ! -f "${opt_k}" ] || [ ! -r "${opt_k}" ]; then
  echo "ERROR:${0##*/}: invalid key specified" 1>&2
  exit 1
fi

JOB_NAME="${opr}"
ACCESS_KEY="${opt_k}"

#####################################################################
# setting
#####################################################################

ACCESS_IP='localhost'
ACCESS_PORT='51000'
ACCESS_USER='jenkins'

#####################################################################
# main routine
#####################################################################

if ! ssh "${ACCESS_USER}@${ACCESS_IP}" -n                           \
     -p "${ACCESS_PORT}" -i "${ACCESS_KEY}"                         \
     help >/dev/null 2>&1; then
  echo "ERROR:${0##*/}: cannot access Jenkins <${ACCESS_IP}:${ACCESS_PORT}>" 1>&2
  exit 1
fi

if ! ssh "${ACCESS_USER}@${ACCESS_IP}" -n                           \
     -p "${ACCESS_PORT}" -i "${ACCESS_KEY}"                         \
     get-job "${JOB_NAME}"; then
  echo "ERROR:${0##*/}: invalid job specified <${JOB_NAME}>" 1>&2
  exit 1
fi
