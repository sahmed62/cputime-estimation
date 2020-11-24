# cputime-estimation
Project exploring CPU-time estimation from hardware-performance counter measurements.

## `./utils/lscache.sh`

Interrogates `sysfs` to find and print information on cache information.

## `./utils/check-system.sh`

Checks kernel arguments and various other parameters for suboptimal settings and makes suggestions for reducing measurement noise.

## `./utils/config-system.sh`

Expects to be run as root. Sets kernel parameters through `sysfs` and `procfs` to help reduce measurement noise (disable CPU-frequency scaling for example).

## `./image-scripts/`

Contains scripts for including in the container image.

## `./run-perf-wo-stress.sh`

Run the container with `perf` with `sleep` without running `stress-ng`.


## `./run-single-core-perf-stres.sh`

Run single container instance with `perf` with `stress-ng`.

## `./run-two-core-perf-stres.sh`

Run two container instances with `perf` with `stress-ng` in the foreground and just `stress-ng` in the background.

## `./aggregate-noise-perf-stat-csv.sh`

Aggregates CSVs from runs from `./run-perf-wo-stress.sh`

## `./aggregate-1core-perf-stat-csv.sh`

Aggregates CSVs from runs from `./run-single-core-perf-stres.sh`

## `./aggregate-2core-perf-stat-csv.sh`

Aggregates CSVs from runs from `./run-two-core-perf-stres.sh`

## `./aggregate-multiple-csv.sh`

Combines multiple aggregated CSVs into a larger CSV.

## `./estimate-event-rates.py`

Performs simple linear regression on events against instructions as the independent variable on the data in an aggregated CSV file. 

## `./first-order-regression-cpi-1-core.py`

Performs multiple linear regression on CPI against events from a single core as the independent variable on the data in an aggregated CSV file.

## `./first-order-regression-cpi.py`

Performs multiple linear regression on CPI against events from all cores as the independent variable on the data in an aggregated CSV file.

