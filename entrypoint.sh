#!/bin/sh
set -e

/app/bin/mudan eval "Mudan.Release.migrate()"

exec "$@"
