#!/bin/bash

cat << \EOF > /etc/apt/sources.list.d/testing.list 
deb http://ftp.jp.debian.org/debian/ testing main non-free
deb-src http://ftp.jp.debian.org/debian/ testing main non-free
deb http://ftp.jp.debian.org/debian/ unstable main non-free
deb-src http://ftp.jp.debian.org/debian/ unstable main non-free
EOF

cat << \EOF > /etc/apt/preferences
Package: *
Pin: release a=stable
Pin-Priority: 900
 
Package: *
Pin: release a=testing
Pin-Priority: 99
 
Package: *
Pin: release a=unstable
Pin-Priority: 89
EOF

apt-get update -y

aptitude install -y -t testing debootstrap
aptitude install -y -t testing ubuntu-keyring


