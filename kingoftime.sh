#!/bin/sh
# Dockerを経由せずに直接叩くシェルスクリプト

SHELL_PATH=`readlink $0`
DIR_NAME="$( cd "$( dirname "$SHELL_PATH" )" && pwd -P )"
source $DIR_NAME/.env
export KOT_USER_ID
export KOT_PSSWORD
export IN_TIME
export OUT_TIME
export OVERTIME_ROUND
export REQUIRED_OVERTIME_REASON_MIN
export DEFAULT_OVERTIME_REASON

$DIR_NAME/src/kingoftime.rb $@
