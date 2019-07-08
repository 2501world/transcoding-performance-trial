#!/bin/sh

PROJECT_NAME=transcoding-performance-trial
GITHUB_USER=2501world

GITHUB_REPOSITORY="https://github.com/${GITHUB_USER}/${PROJECT_NAME}"
GIT_REPO="${GITHUB_REPOSITORY}.git"
ARCHIVE_EXT=tar.gz
REPO_ARCHIVE="${GITHUB_REPOSITORY}/archive/master.${ARCHIVE_EXT}"

DC_SERVICE=perf-trial

PROJECT_DIR="$(pwd)/${PROJECT_NAME}"
RESULT_OUT_DIR="${PROJECT_DIR}/result"

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
    if [ -e /etc/localtime ]; then
      echo "TZ=$(strings /etc/localtime | tail -1)" > "${ENV_FILE}"
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
  docker-compose build
}

cd_dir () {
  cd "${PROJECT_DIR}"
}

cleanup () {
  docker-compose down
}

command_exists () {
  command -v "$@" > /dev/null 2>&1
}

completed_message () {
  echo
  echo 'Trial all completed.'
  echo
  echo 'Result files are generated in:'
  echo "    ${RESULT_OUT_DIR}"
}

confirm_directory () {
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
  get_date_string () {
    date '+%FT%T%z'
  }

  mkdir -p "${RESULT_OUT_DIR}"

  LOG_FILE_NAME="log_$(get_date_string).log"

  docker-compose run "${DC_SERVICE}" \
    | tee "${RESULT_OUT_DIR}/${LOG_FILE_NAME}" \
    && echo "Log file generated:     ${LOG_FILE_NAME}"
}

welcome_message () {
  separator () {
    seq 1 64 | xargs printf '\-%.s' | echo $(cat)
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
  && cleanup \
  && completed_message
