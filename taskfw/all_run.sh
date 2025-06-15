#!/bin/sh
set -eu

#####################################################################
# help
#####################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
Usage   : ${0##*/}
Options : -l<task list>

Execute tasks on <exec list>.

Cloned repositories are stored in './repo'.

-l: Specify the task list (default: ./task.json).
USAGE
  exit 1
}

#####################################################################
# parameter
#####################################################################

opt_l='./task.json'

i=1
for arg in ${1+"$@"}
do
  case "${arg}" in
    -h|--help|--version) print_usage_and_exit ;;
    -l*)                 opt_l="${arg#-l}"    ;;
    *)
      echo "ERROR:${0##*/}: invalid args" 1>&2
      exit 1
      ;;
  esac

  i=$((i + 1))
done

if ! type jq >/dev/null 2>&1; then
  echo "ERROR:${0##*/}: jq not installed" 1>&2
  exit 1
fi

if [ ! -f "${opt_l}" ] || [ ! -r "${opt_l}" ]; then
  echo "ERROR:${0##*/}: list cannot be accessed <${opt_l}>" 1>&2
  exit 1
fi

if ! jq . "${opt_l}" >/dev/null 2>&1; then
  echo "ERROR:${0##*/}: list is invalid <${opt_l}>" 1>&2
  exit 1
fi

EXEC_LIST="${opt_l}"

#####################################################################
# setting
#####################################################################

THIS_DIR="$(dirname "$0")"

EACH_EXEC="${THIS_DIR}/each_run.sh"
REPO_DIR="${THIS_DIR}/repo"

ANSIBLE_SETUP_REPO='https://github.com/altarterminal/ansibletest.git'
ANSIBLE_SETUP_DIR="${REPO_DIR}/$(basename ${ANSIBLE_SETUP_REPO} .git)"
ANSIBLE_SETUP_SCRIPT="${ANSIBLE_SETUP_DIR}/setup/setup_all.sh"

ANSIBLE_ENV_PATH="${HOME}/taskfw/ansible_env"

#####################################################################
# prepare
#####################################################################

mkdir -p "${REPO_DIR}"

if [ -d "${ANSIBLE_SETUP_DIR}" ]; then
  rm -rf "${ANSIBLE_SETUP_DIR}"
fi

if ! git clone -q "${ANSIBLE_SETUP_REPO}" "${ANSIBLE_SETUP_DIR}"; then
  echo "ERROR:${0##*/}: git clone failed <${ANSIBLE_SETUP_REPO}>" 1>&2
  exit 1
fi

if [ ! -f "${ANSIBLE_SETUP_SCRIPT}" ] || [ ! -x "${ANSIBLE_SETUP_SCRIPT}" ]; then
  echo "ERROR:${0##*/}: invalid script specified <${ANSIBLE_SETUP_SCRIPT}>" 1>&2
  exit 1
fi

. "$("${ANSIBLE_SETUP_SCRIPT}" -e"${ANSIBLE_ENV_PATH}")"

####################################################################
# main routine
#####################################################################

jq -c '.[]' "${EXEC_LIST}"                                          |

while read -r line;
do
  url=$(printf '%s\n' "${line}"    | jq -r '."url" // empty')
  branch=$(printf '%s\n' "${line}" | jq -r '."branch" // empty')
  entry=$(printf '%s\n' "${line}"  | jq -r '."entry" // empty')

  {
    echo "=========================================================="
    echo "URL    = ${url}"
    echo "BRANCH = ${branch}"
    echo "ENTRY  = ${entry}"
    echo "=========================================================="
  } 1>&2

  if "${EACH_EXEC}" -d"${REPO_DIR}" -u"${url}" -b"${branch}" "${entry}" 1>&2; then
    echo "OK:${url}:${branch}:${entry}"
    echo "INFO:${0##*/}: succeeded <${url}:${branch}:${entry}>" 1>&2
  else
    echo "NG:${url}:${branch}:${entry}"
    echo "ERROR:${0##*/}: failed <${url}:${branch}:${entry}>" 1>&2
  fi
done                                                                |

awk '
{
  buf[NR] = $0;
}

END {
  print "=========================================================="
  print "Summary"

  is_error = "no";

  for (i = 1; i <= NR; i++) {
    print i, buf[i];

    if (buf[i] ~ /^NG:/) { is_error = "yes"; }
  }

  print "=========================================================="

  if (is_error == "yes") { exit 1; }
}
' 1>&2
