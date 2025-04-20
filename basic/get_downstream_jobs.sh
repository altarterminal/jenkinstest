#!/bin/sh
set -eu

#####################################################################
# help
#####################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
Usage   : ${0##*/} <job definition>
Options : 

Get the downstream jobs.
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

SCRIPT_PATH='."flow-definition"."definition"."script"'

#####################################################################
# main routine
#####################################################################

cat "${JOB_FILE}"                                                   |

xq -r "${SCRIPT_PATH}"                                              |

expand                                                              |

grep 'build '                                                       |

sed 's!^.* *job: *\([^ ]*\) *.*$!\1!'                               |

sed 's!^"!!; s!"$!!'                                                |
sed 's!^'"'"'!!; s!'"'"'$!!'                                        |

cat
