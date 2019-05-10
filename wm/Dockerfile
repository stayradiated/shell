FROM stayradiated/shell as segoeui
RUN mkdir -p /usr/share/fonts/truetype/segoeui/ && \
  cd /usr/share/fonts/truetype/segoeui/ && \
  wget "https://github.com/martinring/clide/blob/master/doc/fonts/segoeui.ttf?raw=true" -O segoeui.ttf && \
  wget "https://github.com/martinring/clide/blob/master/doc/fonts/segoeuib.ttf?raw=true" -O segoeuib.ttf && \
  wget "https://github.com/martinring/clide/blob/master/doc/fonts/segoeuib.ttf?raw=true" -O segoeuii.ttf && \
  wget "https://github.com/martinring/clide/blob/master/doc/fonts/segoeuiz.ttf?raw=true" -O segoeuiz.ttf && \
  wget "https://github.com/martinring/clide/blob/master/doc/fonts/segoeuil.ttf?raw=true" -O segoeuil.ttf && \
  wget "https://github.com/martinring/clide/blob/master/doc/fonts/seguili.ttf?raw=true" -O seguili.ttf && \
  wget "https://github.com/martinring/clide/blob/master/doc/fonts/segoeuisl.ttf?raw=true" -O segoeuisl.ttf && \
  wget "https://github.com/martinring/clide/blob/master/doc/fonts/seguisli.ttf?raw=true" -O seguisli.ttf && \
  wget "https://github.com/martinring/clide/blob/master/doc/fonts/seguisb.ttf?raw=true" -O seguisb.ttf && \
  wget "https://github.com/martinring/clide/blob/master/doc/fonts/seguisbi.ttf?raw=true" -O seguisbi.ttf

FROM stayradiated/shell as gomme
RUN mkdir -p /usr/share/fonts/X11/gomme/ && \
  cd /usr/share/fonts/X11/gomme/ && \
  wget -O gomme.bdf "https://raw.githubusercontent.com/Tecate/bitmap-fonts/master/bitmap/gomme/Gomme10x20n.bdf"

FROM stayradiated/shell as light
RUN wget -O light.deb "https://github.com/haikarainen/light/releases/download/v1.2/light_1.2_amd64.deb" && \
  dpkg -i light.deb && \
  rm light.deb

###
### MAIN IMAGE
###

FROM stayradiated/shell

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    acpi \
    audacity \
    bspwm \
    dbus-x11 \
    exfat-fuse \
    libxv1 \
    libgl1-mesa-dri \
    libgl1-mesa-glx \
    fonts-noto \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    libpulse0 \
    mesa-utils \
    mesa-utils-extra \
    psmisc \
    pulseaudio \
    qpdfview \
    redshift \
    rofi \
    sxhkd \
    ttf-ubuntu-font-family \
    x11-utils \
    x11-xkb-utils \
    x11-xserver-utils \
    xdg-utils \
    xdo \
    xfonts-utils && \
  apt-get clean && \
  echo enable-shm=no >> /etc/pulse/client.conf

COPY --from=segoeui /usr/share/fonts/truetype/segoeui /usr/share/fonts/truetype/segoeui
COPY --from=gomme /usr/share/fonts/X11/gomme /usr/share/fonts/X11/gomme

RUN cd /etc/fonts/conf.d && \
  rm 10* 70-no-bitmaps.conf && \
  ln -s ../conf.avail/70-yes-bitmaps.conf . && \
  dpkg-reconfigure fontconfig && \
  fc-cache -fv

COPY --from=light /usr/bin/light /usr/local/bin/light

# copy config files
COPY --chown=admin:admin ./configs/alacritty.yml .config/alacritty/alacritty.yml
COPY --chown=admin:admin ./configs/bspwmrc .config/bspwm/bspwmrc
COPY --chown=admin:admin ./configs/sxhkdrc .config/sxhkd/sxhkdrc
COPY --chown=admin:admin ./configs/xinitrc .xinitrc

ENV PULSE_SERVER /run/pulse/native

CMD /home/admin/.xinitrc
USER admin
