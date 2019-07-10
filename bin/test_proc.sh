#!/bin/ash

VIDEO_NUM="$1"

call_sub_proc () {
  local SUB_PROC="${BIN_DIR}/sub_proc.sh"

  echo
  echo "Video transcoding..."

  get_existing_video_files \
    | sort \
    | sed -n "1,${VIDEO_NUM}p" \
    | xargs \
      -I% \
      -P "${VIDEO_NUM}" \
      sh -c "${SUB_PROC} %"
}

collect_videos () {
  local EXISTING_NUM=$(count_existing_videos)
  local VIDEO_NUM_TO_GET=$(( ${VIDEO_NUM} - ${EXISTING_NUM} ))

  echo "Requiring videos: ${VIDEO_NUM}"

  if [ ${EXISTING_NUM} -gt 0 ]; then
    echo "Found already downloaded videos: ${EXISTING_NUM}"
  fi

  if [ ${VIDEO_NUM_TO_GET} -le 0 ]; then
    return 0
  fi

  echo "Need to download videos: ${VIDEO_NUM_TO_GET}"

  local i=0

  while [ $i -lt ${VIDEO_NUM_TO_GET} ]; do
    get_video
    local RET=$?

    if [ ${RET} -eq 0 ]; then
      i=$(( $i + 1 ))
    elif [ ${RET} -gt 1 ]; then
      return 1
    fi
  done
}

count_existing_videos () {
  get_existing_video_files | wc -l
}

get_existing_video_files () {
  find "${VIDEO_OUT_DIR}" -type f -iname '*.mp4' -maxdepth 1
}

get_video () {
  local RES
  local OUT_FILE

  local PEXELS_JQ_FILTER=".videos[0].video_files | map(select(.height == ${VIDEO_HEIGHT} and .width == ${VIDEO_WIDTH} and (.link | test(\"profile_id=${VIMEO_PROFILE_ID}\")) ))[0]"

  call_api () {
    local PEXELS_API_ROOT="https://api.pexels.com"
    local PEXELS_API_VIDEO_POPULAR="/videos/popular"

    local REQ_PAGE="$(( ${RANDOM} % 1000 + 1 ))"
    local REQ_OPT="?per_page=1&min_width=${VIDEO_WIDTH}&min_height=${VIDEO_HEIGHT}&min_duration=${VIDEO_DURATION}&page=${REQ_PAGE}"

    local RET

    RES="$( \
      curl \
        -sS \
        -H "Authorization: ${PEXELS_API_KEY}" \
        "${PEXELS_API_ROOT}${PEXELS_API_VIDEO_POPULAR}${REQ_OPT}" \
    )"
    RET=$?

    if echo "${RES}" | grep 'error' > /dev/null; then
      RET=2
    fi

    return ${RET}
  }

  download_video () {
    local VIDEO_TYPE
    local VIDEO_TYPE_MP4="video/mp4"
    local RET

    VIDEO_TYPE="$(get_type)"
    RET=$?

    if [ ${RET} -ne 0 ]; then
      return 2
    fi

    if ! [ "${VIDEO_TYPE}" = "${VIDEO_TYPE_MP4}" ]; then
      return 1
    fi

    local VIDEO_ID="$(get_id)"
    local VIDEO_LINK="$(get_link)"

    OUT_FILE="${VIDEO_OUT_DIR}/${VIDEO_ID}.mp4"

    echo "Video found: ${VIDEO_ID}"

    curl \
      -L \
      -o "${OUT_FILE}" \
      "${VIDEO_LINK}"
  }

  get_framerate () {
    ffprobe \
      -v error \
      -show_streams \
      -of json \
      -i "${OUT_FILE}" \
      | jq \
        -r \
        '.streams | map(select(.codec_name == "h264"))[0].r_frame_rate'
  }

  get_id () {
    echo "${RES}" \
      | jq \
        -r \
        '.videos[0].id'
  }

  get_link () {
    echo "${RES}" \
      | jq \
        -r \
        "${PEXELS_JQ_FILTER}.link"
  }

  get_type () {
    echo "${RES}" \
      | jq \
        -r \
        "${PEXELS_JQ_FILTER}.file_type"
  }

  validate_framerate () {
    local f="$(get_framerate)"

    echo "Video framerate is: ${f}"

    if ! [ "$f" = "30/1" ] && ! [ "$f" = "30000/1001" ]; then
      echo "This file is not suitable. Removing..."

      rm "${OUT_FILE}"

      return 1
    fi
  }

  call_api \
    && download_video \
    && echo "File downloaded: ${OUT_FILE}" \
    && validate_framerate
}

collect_videos \
  && call_sub_proc \
  && echo "Completed."
