#!/bin/bash

TOP_DIR=${PWD}/Build

case "$1" in 
        server|desktop)
                ROOT=${TOP_DIR}/ubuntu-$1
                PKG=ubuntu-$1
        ;;
        *)
                echo Usage: $0 "[server|desktop]";
                exit
        ;;
esac;

gunzip -c ${TOP_DIR}/${PKG}.tgz | tar --numeric-owner --acls --xattrs -tpf -

