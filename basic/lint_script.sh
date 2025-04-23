#!/bin/sh
set -eu

#####################################################################
# help
#####################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
Usage   : ${0##*/} <jenkinsfile>
Options : -k<access key>

Lint a jenkinsfile throught Jenkins.

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

if   [ "${opr}" = '' ] || [ "${opr}" = '-' ]; then
  opr='-'
elif [ ! -f "${opr}" ] || [ ! -r "${opr}"  ]; then
  echo "ERROR:${0##*/}: invalid file specified <${opr}>" 1>&2
  exit 1
fi

if [ ! -f "${opt_k}" ] || [ ! -r "${opt_k}" ]; then
  echo "ERROR:${0##*/}: invalid key specified" 1>&2
  exit 1
fi

JENKINS_FILE="${opr}"
ACCESS_KEY="${opt_k}"

#####################################################################
# setting
#####################################################################

ACCESS_IP='localhost'
ACCESS_PORT='51000'
ACCESS_USER='jenkins'

THIS_DATE=$(date '+%Y%m%d_%H%M%S')

TEMP_NAME="${TMPDIR:-/tmp}/${0##*/}_${THIS_DATE}_XXXXXX"

#####################################################################
# prepare
#####################################################################

TEMP_FILE="$(mktemp "${TEMP_NAME}")"

trap "[ -e ${TEMP_FILE} ]   && rm ${TEMP_FILE}" EXIT

cat "${JENKINS_FILE}" >"${TEMP_FILE}"

#####################################################################
# main routine
#####################################################################

if ! ssh "${ACCESS_USER}@${ACCESS_IP}" -n                           \
     -p "${ACCESS_PORT}" -i "${ACCESS_KEY}"                         \
     help >/dev/null 2>&1; then
  echo "ERROR:${0##*/}: cannot access Jenkins <${ACCESS_IP}:${ACCESS_PORT}>" 1>&2
  exit 1
fi

if ! ssh "${ACCESS_USER}@${ACCESS_IP}"                              \
     -p "${ACCESS_PORT}" -i "${ACCESS_KEY}"                         \
     declarative-linter <"${TEMP_FILE}"; then
  echo "ERROR:${0##*/}: there are some errors" 1>&2
  exit 1
fi
