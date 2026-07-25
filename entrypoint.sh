#!/bin/sh
set -e

/app/bin/mundan eval "Mudan.Release.migrate()"

exec "$@"
