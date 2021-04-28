#! /bin/sh
set -exu
echo $(env) 1>&2
echo '{"version": 0.1, "name": "se2cf"}'

signal-cli --verbose --config . --username +$USER --output=json stdio
