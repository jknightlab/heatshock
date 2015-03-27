## Docker file to create reproducible environment for heat shock analysis
FROM bioconductor/release_microarray:20150119
MAINTAINER Peter Humburg <peter.humburg@gmail.com>

## Install additional software packages
RUN apt-get update -y && apt-get install -y haskell-platform nginx lmodern plink

## Install pandoc
RUN cabal update && cabal install pandoc

## Install additional R packages
RUN Rscript -e "biocLite(c('sparcl'))"

## Add basic instruction to display for interactive containers
COPY config/message.txt /etc/motd
RUN echo "cat /etc/motd" >> /etc/bash.bashrc

## additional user configuration
RUN echo chown -R '$USER' /usr/share/nginx/html >> /usr/bin/userconf.sh && echo chown -R '$USER' /analysis

## control access to websites
COPY config/access.conf /etc/nginx/conf.d/access.conf
COPY config/access.conf /etc/rstudio/ip-rules

## Add additional programs to run at startup
COPY config/supervisored.conf /tmp/
RUN cat /tmp/supervisored.conf >> /etc/supervisor/conf.d/supervisord.conf

## Add the raw data to the image
COPY data/ /analysis/data/

## Add R and pandoc files
COPY heatshock_analysis.* default.pandoc /analysis/
COPY include/ /analysis/include/
COPY html/ /analysis/html/

ENV USER=rstudio
WORKDIR /analysis/
