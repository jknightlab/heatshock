## Docker file to create reproducible environment for heat shock analysis
FROM bioconductor/release_microarray:20150119
MAINTAINER Peter Humburg <peter.humburg@gmail.com>

## Install pandoc
RUN apt-get update -y && apt-get install -y haskell-platform
RUN cabal update && cabal install pandoc

## Add the raw data to the image
COPY data/ /heatshock/data/

## Add R and pandoc files
COPY heatshock_analysis.* default.pandoc /heatshock/
COPY include/ /heatshock/include/ 