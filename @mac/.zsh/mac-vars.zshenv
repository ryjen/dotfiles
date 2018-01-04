export GOPATH=${HOME}/.go

[ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh

# Mutt
export MUTT_FROM="[ryan@coda.life]"
export MUTT_IMAP_PASS="zyigokmngvqckgke"
export MUTT_IMAP_USER="c0der78@gmail.com"
export MUTT_REAL_NAME="Ryan Jennings"

# Android
export ANDROID_HOME=${HOME}/Library/Android/sdk

export PATH=$PATH:${HOME}/bin:${GOPATH}/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin

