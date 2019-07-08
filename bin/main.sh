#!/bin/ash

#
# Global configurations
#

# Duration to use for transcoding
export VIDEO_DURATION=5

# Video size to use
export VIDEO_WIDTH=1920
export VIDEO_HEIGHT=1080

# Vimeo profile id
export VIMEO_PROFILE_ID=175 # 1080p, 30fps

#
# Directories to use
#
export BIN_DIR=/opt/bin
export RESULT_OUT_DIR=/opt/result
export VIDEO_OUT_DIR=/opt/data/videos

#
# Available test cases
#
TEST_CASE_AVAILABLE="01, 02, 03, 04, 05"

# Default test case
TEST_CASE_DEFAULT=01

check_test_case () {
  if ! echo "${TEST_CASE_AVAILABLE}," | grep "${TEST_CASE}," > /dev/null; then
    echo "Given test case is not available: ${TEST_CASE}" 1>&2
    usage
  fi
}

clean_prev_results () {
  rm -rf "${CASE_RESULT_OUT_DIR}"/trial_*
}

collect_spec () {
  collect_cpu () {
    cp /proc/cpuinfo "${RESULT_OUT_DIR}"
  }

  collect_mem () {
    cp /proc/meminfo "${RESULT_OUT_DIR}"
  }

  decode_mem () {
    dmidecode --type memory > "${RESULT_OUT_DIR}/dmidecode"

    return 0
  }

  collect_cpu \
    && collect_mem \
    && decode_mem
}

get_num_processor () {
  cat /proc/cpuinfo \
    | grep processor \
    | wc -l
}

parse_args () {
  param_usage () {
    if [ -z "$2" ] || echo "$2" | grep -E '^-+' > /dev/null; then
      echo "${PROGNAME}: option requires an argument -- $1" 1>&2
      exit 1
    fi
  }

  local OPT

  for OPT in "$@"; do
    case "${OPT}" in
      -h | --help)
        usage
        ;;
      -c | --case)
        param_usage "$1" "$2"
        TEST_CASE="$2"
        shift 2
        ;;
      -*)
        echo "${PROGNAME}: illegal option -- '$(echo $1 | sed 's/^-*//')'" 1>&2
        exit 1
        ;;
    esac
  done
}

prepare_out_dir () {
  mkdir -p "${CASE_RESULT_OUT_DIR}"
}

show_message () {
    cat << _EOS_
+***************************************************************
| Test case: case${TEST_CASE}
+***************************************************************

_EOS_
}

usage () {
  cat << _EOS_ 1>&2
Usage: ${PROGNAME} [OPTIONS]

Options:
  -h, --help
    Shows this help

  -c, --case ARG
    Specify the test case name
    Available: ${TEST_CASE_AVAILABLE}
    Default: ${TEST_CASE_DEFAULT}

_EOS_

  exit 1
}

PROGNAME="$(basename $0)"
export TEST_CASE="${TEST_CASE_DEFAULT}"

parse_args "$@" \
  && check_test_case

export CASE_RESULT_OUT_DIR="${RESULT_OUT_DIR}/case${TEST_CASE}"
export NUM_PROCESSOR=$(get_num_processor)

show_message \
  && clean_prev_results \
  && collect_spec \
  && prepare_out_dir \
  && "${BIN_DIR}/do_test.sh" \
  && echo "All test finished."
