#!/bin/sh -ex

cat /usr/local/etc/recursor.conf.tpl | envtpl | tee /usr/local/etc/recursor.conf

exec "$@"