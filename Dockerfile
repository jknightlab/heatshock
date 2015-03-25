## Docker file to create reproducible environment for heat shock analysis
FROM bioconductor/release_microarray:20150119
MAINTAINER Peter Humburg <peter.humburg@gmail.com>

## Install additional software packages
RUN apt-get update -y && apt-get install -y haskell-platform nginx lmodern plink

## Install pandoc
RUN cabal update && cabal install pandoc

## Install additional R packages
RUN Rscript -e "biocLite(c('sparcl'))"

## create user
RUN useradd -m heatshock && echo 'heatshock:analysis' | chpasswd && echo "heatshock ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers && chown -R heatshock /usr/share/nginx/html

## configure nginx
RUN echo "if [ \`service nginx status | grep -c \"not\"\` == 1 ]; then sudo service nginx start; echo webserver started; fi" >> /home/heatshock/.bashrc && echo "allow 90.195.50.229; allow 129.67.44.0/22; deny all;" > /etc/nginx/conf.d/access.conf

## Add the raw data to the image
COPY data/ /home/heatshock/data/

## Add R and pandoc files
COPY heatshock_analysis.* default.pandoc start.sh home/heatshock/
COPY include/ /home/heatshock/include/
COPY html/ /home/heatshock/html/

RUN chown -R heatshock /home/heatshock && chgrp -R heatshock /home/heatshock

USER heatshock

WORKDIR /home/heatshock/ 
ENV DISPLAY :0
CMD ./start.sh && /bin/bash
