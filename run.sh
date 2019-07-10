#!/bin/sh

PROJECT_NAME=transcoding-performance-trial
GITHUB_USER=2501world

GITHUB_REPOSITORY="https://github.com/${GITHUB_USER}/${PROJECT_NAME}"
GIT_REPO="${GITHUB_REPOSITORY}.git"
ARCHIVE_EXT=tar.gz
REPO_ARCHIVE="${GITHUB_REPOSITORY}/archive/master.${ARCHIVE_EXT}"

DC_SERVICE=perf-trial
DC_TAG="${PROJECT_NAME//-/}_${DC_SERVICE}:latest"

add_env_file () {
  local ENV_FILE="${PROJECT_DIR}/.env"

  set_pexels () {
    echo
    echo 'Setting up API key configuration:'
    echo '    Please input API key for pexels.com'
    printf '%s' 'PEXELS_API_KEY='

    read PEXELS_API_KEY

    echo "PEXELS_API_KEY=${PEXELS_API_KEY}" >> "${ENV_FILE}"

    echo
    echo "Pexels API key was written to the file: ${ENV_FILE}"
    echo 'You can edit the file later.'
  }

  set_tz () {
    local BIN_CMD=strings

    if ! command_exists ${BIN_CMD}; then
      BIN_CMD=cat
    fi

    if [ -e /etc/localtime ]; then
      echo "TZ=$(${BIN_CMD} /etc/localtime | tail -1)" > "${ENV_FILE}"
    fi
  }

  if [ -e "${ENV_FILE}" ]; then
    echo
    echo "Env file already exists: ${ENV_FILE}"
  else
    set_tz \
      && set_pexels
  fi
}

build_container () {
  sudo docker image build \
    --tag "${DC_TAG}" \
    .
}

cd_dir () {
  cd "${PROJECT_DIR}"
}

cleanup () {
  sudo docker container prune -f
}

command_exists () {
  command -v "$@" > /dev/null 2>&1
}

completed_message () {
  echo
  echo 'Trial all completed.'
  echo
  echo 'Result file is generated:'
  echo "    ${RESULTS_FILE}"
}

confirm_directory () {
  if [ "$(basename "$(pwd)")" = "${PROJECT_NAME}" ]; then
    PROJECT_DIR="$(pwd)"
  else
    PROJECT_DIR="$(pwd)/${PROJECT_NAME}"
  fi
  RESULT_OUT_DIR="${PROJECT_DIR}/result"

  echo

  if [ -d "${PROJECT_DIR}" ]; then
    echo 'This script uses the folder:'
  else
    echo 'This script creates a folder under the current directory:'
  fi

  echo "    ${PROJECT_DIR}"
  echo
  printf '%s' 'Continue? (Y/n): '

  local INPUT

  read INPUT

  case "${INPUT}" in
    n* | N*)
      echo "Performance trial is not executed." 1>&2
      exit 1
      ;;
  esac
}

deflate_results () {
  cd "${RESULT_OUT_DIR}"

  local ARCHIVE_FILENAME="results_$(get_date_string).${ARCHIVE_EXT}"
  RESULTS_FILE="${RESULT_OUT_DIR}/${ARCHIVE_FILENAME}"

  find . \! -name "results_*.${ARCHIVE_EXT}" \! -name '.*' \
    | xargs tar -czf - \
    > "${ARCHIVE_FILENAME}"
}

generate_csv_result () {
  local CSV_FILE="${RESULT_OUT_DIR}/result_all.csv"
  local FILE
  local NEED_HEADER=1

  for FILE in $(find "${RESULT_OUT_DIR}" -name 'result.csv' | sort); do
    if [ ${NEED_HEADER} -eq 1 ]; then
      cp "${FILE}" "${CSV_FILE}"
      NEED_HEADER=0
    else
      cat "${FILE}" \
        | sed -n '2,$p' \
        >> "${CSV_FILE}"
    fi
  done
}

get_date_string () {
  date '+%FT%T%z'
}

init_git_repository () {
  download_via_http () {
    if [ -d "${PROJECT_DIR}" ]; then
      rm -rf "${PROJECT_DIR}"
    fi

    local FILE="${PROJECT_NAME}.${ARCHIVE_EXT}"

    curl -fsSL "${REPO_ARCHIVE}" -o "${FILE}" \
      && tar -xvf "${FILE}" \
      && mv "${PROJECT_NAME}-master" "${PROJECT_NAME}" \
      && rm -f "${FILE}"
  }

  git_clone () {
    if [ -d "${PROJECT_DIR}" ]; then
      cd "${PROJECT_DIR}" \
        && git pull
    else
      git clone "${GIT_REPO}" "${PROJECT_DIR}"
    fi
  }

  if command_exists git; then
    git_clone
  else
    download_via_http
  fi
}

install_docker () {
  if command_exists docker && [ -e /var/run/docker.sock ]; then
    echo 'You already have Docker installed.'

    docker version
  else
    curl -fsSL get.docker.com \
      | sh
  fi
}

run_script () {
  run_case () {
    local TEST_CASE="$1"
    local CASE_RESULT_OUT_DIR="${RESULT_OUT_DIR}/case${TEST_CASE}"

    mkdir -p "${CASE_RESULT_OUT_DIR}"

    local LOG_FILE_NAME="log_$(get_date_string).log"

    sudo docker container run \
      --device /dev/mem:/dev/mem \
      --env-file .env \
      --interactive \
      --privileged \
      --tty \
      --volume "$(pwd)/data:/opt/data" \
      --volume "$(pwd)/result:/opt/result" \
      "${DC_TAG}" \
        --case "${TEST_CASE}" \
      | tee "${CASE_RESULT_OUT_DIR}/${LOG_FILE_NAME}" \
      && echo "Log file generated: case${TEST_CASE}/${LOG_FILE_NAME}"
  }

  run_case 01 \
    && run_case 02 \
    && run_case 03 \
    && run_case 04 \
    && run_case 05
}

welcome_message () {
  separator () {
    seq 1 64 | xargs printf '\55%.s' | echo $(cat)
  }

  separator
  echo "| $(printf '%-60s' "${PROJECT_NAME}") |"
  separator
}

welcome_message \
  && confirm_directory \
  && init_git_repository \
  && install_docker \
  && cd_dir \
  && add_env_file \
  && build_container \
  && run_script \
  && generate_csv_result \
  && deflate_results \
  && cleanup \
  && completed_message
