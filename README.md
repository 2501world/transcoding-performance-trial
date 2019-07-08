# transcoding-performance-trial

[![license](https://img.shields.io/github/license/2501world/transcoding-performance-trial.svg?style=flat-square)](LICENSE)
[![last commit](https://img.shields.io/github/last-commit/2501world/transcoding-performance-trial.svg?style=flat-square)](https://github.com/2501world/transcoding-performance-trial/commits/master)
[![repo size](https://img.shields.io/github/repo-size/2501world/transcoding-performance-trial.svg?style=flat-square)](https://github.com/2501world/transcoding-performance-trial/archive/master.zip)

> Runs FFmpeg transcoding processes simultaneously and measures CPU performance

## Usage

```shell
curl -fsSL https://raw.githubusercontent.com/2501world/transcoding-performance-trial/master/run.sh | sh
```

## Requirements

This script needs following commands installed on the measuring machine.

* `/bin/sh`
  - `bash` is better
* `curl`
* `tar`
* `gunzip`
* `git`
  - uses `curl` instead if not installed
* Docker-CE
  - automatically be installed via [get.docker.com]

This script also needs following API key.

* Pexels API
  * You can get yours on [Pexels API].

## How it works

When you run `run.sh` on your local environment, the script does:

1. Clone this repository into your current directory
2. Install Docker-CE
3. Build a docker image (based on Alpine Linux)
4. Run a measuring script on a docker container
5. Generate result files

You can run this script multiple times (works idempotently).

## Results

This script exports 2 result files:

1. A zipped file
    - Filename: `result/results_*.zip`
    - Contents are:
      + Local machine information: `cpuinfo`, `meminfo`, `dmidecode`d outputs
      + `time`d results
2. A log file
    - Filename: `result/log_*.log`

## Disclaimer

* This script installs Docker-CE, and keep it installed on your machine.
* This script keeps files within your working directory.
  - You can safely delete all those files.

## License

`transcoding-performance-trial` is made available under the terms of the [MIT license].

[get.docker.com]:http://get.docker.com
[Pexels API]:https://www.pexels.com/api/new
[MIT license]:LICENSE
