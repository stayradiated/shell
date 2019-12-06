#!/usr/bin/env bash

set -ex

cp -r \
  ~/.myclirc \
  ~/.npmrc \
  ~/.mish_production \
  ~/.mish_internal \
  ~/.jackrc \
  ~/.flynnrc \
  ~/.flynn \
  ~/.ssh \
  ~/.aws \
  ~/.ngrok2 \
  ~/.xinitrc \
  \
  files

cp -r \
  ~/.config/alacritty \
  ~/.config/bspwm \
  ~/.config/sxhkd \
  ~/.config/logview \
  ~/.config/ranger \
  ~/.config/hub \
  \
  files/.config

cp -r ~/bin/* files/bin/
