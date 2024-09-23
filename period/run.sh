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

readonly EXEC_LIST=${opr}

#####################################################################
# main routine
#####################################################################

jq -c '.[]' "${EXEC_LIST}"                                          |

while read -r line;
do
  url=$(printf '%s\n' "${line}"   | jq -r '."url"')
  hash=$(printf '%s\n' "${line}"  | jq -r '."hash"')
  entry=$(printf '%s\n' "${line}" | jq -r '."entry"')

  dir=$(basename "${url}" '.git')

  echo '============================================================='
  echo "url   = ${url}"
  echo "hash  = ${hash}"
  echo "entry = ${entry}"
  echo '============================================================='

  if [ -d "${dir}" ]; then
    rm -rf "${dir}"
  fi

  if ! git clone "${url}" >/dev/null; then
    echo "${0##*/}:ERROR: the repo is invalid <${url}>" 1>&2
    exit 1
  fi

  if [ -z "${hash}" ]; then
    if git -C "${dir}" branch -r | grep -q '^ *origin/master$'; then
      hash='origin/master'
    elif git -C "${dir}" branch -r | grep -q '^ *origin/main$'; then
      hash='origin/main'
    else
      echo "${0##*/}:ERROR: some error for <${url}>" 1>&2
      exit 1
    fi
  fi

  if ! git -C "${dir}" checkout "${hash}" >/dev/null; then
    echo "${0##*/}:ERROR: the hash is invalid <${hash}>" 1>&2
    exit 1
  fi

  if [ ! -f "${dir}/${entry}" ]; then
    echo "${0##*/}:ERROR: the entory not exist <${dir}/${entry}>" 1>&2
    exit 1
  fi

  if [ ! -x "${dir}/${entry}" ]; then
    echo "${0##*/}:ERROR: the entory not executable <${dir}/${entry}>" 1>&2
    exit 1
  fi

  (
    cd "${dir}"
    ./"${entry}"
  )
done
