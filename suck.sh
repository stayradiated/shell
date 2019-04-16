#!/usr/bin/env bash

set -ex

cp -r \
  ~/.usqlpass \
  ~/.npmrc \
  ~/.mish_production \
  ~/.mish_internal \
  ~/.jackrc \
  ~/.flynnrc \
  ~/.flynn \
  ~/.ssh \
  ~/.aws \
  \
  files

cp -r \
  ~/.config/logview \
  ~/.config/ranger \
  ~/.config/hub \
  \
  files/.config
