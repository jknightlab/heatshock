## Docker file to create reproducible environment for heat shock analysis
FROM bioconductor/release_microarray:20150104
MAINTAINER Peter Humburg
## Add the raw data to the image
COPY data/ /heatshock/data/