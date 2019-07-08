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

clean_prev_results () {
  rm -rf "${RESULT_OUT_DIR}"/trial_*
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

deflate_results () {
  get_date_string () {
    date '+%FT%T%z'
  }

  cd "${RESULT_OUT_DIR}"

  local ZIP_FILENAME="results_$(get_date_string).zip"

  find . \! -name 'results_*.zip' \! -name '.*' \
    | xargs zip -r "${ZIP_FILENAME}"

  echo "Results file generated: ${ZIP_FILENAME}"
}

get_num_processor () {
  cat /proc/cpuinfo \
    | grep processor \
    | wc -l
}

prepare_out_dir () {
  mkdir -p "${VIDEO_OUT_DIR}"
}

export NUM_PROCESSOR=$(get_num_processor)

clean_prev_results \
  && collect_spec \
  && prepare_out_dir \
  && "${BIN_DIR}/do_test.sh" \
  && echo "All test finished." \
  && deflate_results
