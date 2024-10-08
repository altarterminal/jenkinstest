#!/bin/sh
set -eu

#####################################################################
# help
#####################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
Usage   : ${0##*/} <exec list>
Options :

execute tasks on <exec list>.

specify the <exec list> (default: task.json).

cloned repositories are stored in 'all_store'.
ansible environment is used or made on '${HOME}/period_ws/ansible_env'
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
      if [ $i -eq $# ]; then
        opr=${arg}
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
readonly STORE_DIR="${CUR_DIR}/all_store"

readonly ANSIBLE_SETUP="${CUR_DIR}/setup_ansible.sh"
readonly ANSIBLE_ENV_PATH="${HOME}/period_ws/ansible_env"

#####################################################################
# prepare
#####################################################################

# prepare ansible
if ! type ansible >/dev/null 2>&1; then
  # check ansible env. install it if it is not found
  ./"${ANSIBLE_SETUP}" "${ANSIBLE_ENV_PATH}"

  # enable ansible
  . "${ANSIBLE_ENV_PATH}/bin/activate"
fi

#####################################################################
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

  if "${EACH_EXEC}" -d"${STORE_DIR}" -u"${url}" -b"${branch}" "${entry}" 1>&2; then
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
