ARG         IMAGE_BASE

FROM        $IMAGE_BASE
MAINTAINER  Mark Barinstein <mark.barinstein@gmail.com>
ARG         INSTALLCMD=/setup/install.sh

COPY        cfg/ /setup/
RUN         --mount=type=secret,id=secret $INSTALLCMD
STOPSIGNAL  SIGRTMIN+3

USER        root
WORKDIR     /
ENTRYPOINT  ["/sbin/init"]
