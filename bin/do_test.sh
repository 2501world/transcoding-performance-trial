#!/bin/ash

# Initial video num
VIDEO_NUM=$(( ${NUM_PROCESSOR} / 2 ))
PREV_VIDEO_NUM=${VIDEO_NUM}

do_test () {
  export TRIAL_RESULT_DIR="${RESULT_OUT_DIR}/trial_$(printf '%02d' "${VIDEO_NUM}")"

  call_test_proc () {
    "${BIN_DIR}/test_proc.sh" "${VIDEO_NUM}"
  }

  prepare_result_dir () {
    mkdir -p "${TRIAL_RESULT_DIR}"
  }

  show_message () {
    cat << _EOS_
+===============================
| Trial video num: ${VIDEO_NUM}

_EOS_
  }

  validate_results_all () {
    local FILE
    local INDEX=0
    local RET=0

    for_each () {
      for FILE in "${TRIAL_RESULT_DIR}"/time_*.json; do
        INDEX=$(( ${INDEX} + 1 ))

        if ! validate_file; then
          RET=1
        fi
      done
    }

    validate_file () {
      local TIME_TOOK_IN_REAL=$( \
        cat "${FILE}" \
          | jq -r ".time.real_fmt" \
      )
      local IS_REAL_IN_DURATION=$( \
        cat "${FILE}" \
          | jq -r ".time.real <= ${VIDEO_DURATION}" \
      )

      echo "Video $(printf '%2d' ${INDEX}) took ${TIME_TOOK_IN_REAL}: ${IS_REAL_IN_DURATION}"

      [ "${IS_REAL_IN_DURATION}" = "true" ]
    }

    echo
    echo "Validating results: objective ${VIDEO_DURATION}s"

    for_each

    if [ ${RET} -eq 0 ]; then
      echo "Yay! Objective achieved."
    else
      echo "Took too long. Objective unachieved."
    fi
    echo

    return ${RET}
  }

  show_message \
    && prepare_result_dir \
    && call_test_proc \
    && validate_results_all
}

step_up () {
  if do_test; then
    PREV_VIDEO_NUM=${VIDEO_NUM}
    VIDEO_NUM=$(( ${VIDEO_NUM} + 1 ))

    step_up
  else
    # One more push
    VIDEO_NUM=$(( ${VIDEO_NUM} + 1 ))

    do_test

    echo "+------------------+"
    echo "| Final result: $(printf '%2d' ${PREV_VIDEO_NUM}) |"
    echo "+------------------+"
    echo
  fi
}

step_up
