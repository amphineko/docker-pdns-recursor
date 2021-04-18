#!/bin/bash -ex

[ -z "${RECURSOR_allow_from}" ] && export RECURSOR_allow_from="0.0.0.0/0; ::/0"
[ -z "${RECURSOR_local_address}" ]  && export RECURSOR_local_address="0.0.0.0, ::"
[ -z "${RECURSOR_threads}" ]  && export RECURSOR_threads=1

for k in "${!RECURSOR_@}"; do 
    echo $(echo "$k" | sed -r 's/^RECURSOR_(.*)$/\1/; s/_/-/g')"=${!k}" >> /usr/local/etc/powerdns/recursor.conf;
done

exec "$@"
