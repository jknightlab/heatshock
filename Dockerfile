## Docker file to create reproducible environment for heat shock analysis
FROM bioconductor/release_microarray:20150119
MAINTAINER Peter Humburg <peter.humburg@gmail.com>

## Install additional software packages
RUN apt-get update -y && apt-get install -y haskell-platform nginx

## Install pandoc
RUN cabal update && cabal install pandoc

## Install additional R packages
RUN Rscript -e "biocLite(c("optparse"))"

## create user
RUN useradd -m heatshock

## Add the raw data to the image
COPY data/ /home/heatshock/data/

## Add R and pandoc files
COPY heatshock_analysis.* default.pandoc /home/heatshock/
COPY include/ /home/heatshock/include/

RUN chown -R heatshock /home/heatshock && chgrp -R heatshock /home/heatshock
USER heatshock

WORKDIR /home/heatshock/ 
