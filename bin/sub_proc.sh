#!/bin/ash

FILE="$1"
VIDEO_OUT_DIR="${FILE%.*}"
FILE_BASENAME="$(basename ${VIDEO_OUT_DIR})"

TIME_FMT=$(cat << _EOS_
{
  "time": {
    "real": %e,
    "real_fmt": "%E",
    "system": %S,
    "user": %U,
    "cpu_percentage": "%P"
  },
  "memory": {
    "resident_set_size": {
      "maximum": %M,
      "average": %t,
      "unit": "kbytes"
    },
    "total_size": {
      "average": %K,
      "unit": "kbytes"
    },
    "unshared_data_size": {
      "average": %D,
      "unit": "kbytes"
    },
    "stack_size": {
      "average": %p,
      "unit": "kbytes"
    },
    "shared_text_size": {
      "average": %X,
      "unit": "kbytes"
    },
    "page_size": {
      "system": %Z,
      "unit": "bytes"
    },
    "page_faults": {
      "major_requiring_io": %F,
      "minor_reclaming_frame": %R
    },
    "swaps": %W,
    "context_switches": {
      "involuntary": %c,
      "voluntary": %w
    }
  },
  "io": {
    "file_system": {
      "inputs": %I,
      "outputs": %O
    },
    "socket_messages": {
      "received": %r,
      "sent": %s
    },
    "signals_delivered": %k
  },
  "exit_status": %x
}
_EOS_
)

do_transcoding () {
  get_opt () {
    local BITRATE=$1
    local SIZE=$2
    local EXT=$3

    echo \
      -an \
      -c:v libx264 \
      -b:v ${BITRATE} \
      -f flv \
      -g 30 \
      -r 30 \
      -s ${SIZE} \
      -preset superfast \
      -profile:v baseline \
      "${VIDEO_OUT_DIR}/${EXT}.mp4"
  }

  time \
    -f "${TIME_FMT}" \
    -o "${TRIAL_RESULT_DIR}/time_${FILE_BASENAME}.json" \
    ffmpeg \
      -y \
      -v error \
      -threads 1 \
      -t "${VIDEO_DURATION}" \
      -i "${FILE}" \
      $(get_opt 4500k 1920x1080 1080p) \
      $(get_opt 2500k 1280x720 720p) \
      $(get_opt 400k 426x240 240p)
}

prepare_out_dir () {
  mkdir -p "${VIDEO_OUT_DIR}"
}

prepare_out_dir \
  && do_transcoding
