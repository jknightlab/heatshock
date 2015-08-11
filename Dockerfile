## Docker file to create reproducible environment for heat shock analysis
FROM humburg/eqtl-intro 
MAINTAINER Peter Humburg <peter.humburg@gmail.com>

## Install additional software packages
RUN apt-get update -y && apt-get install -y nginx lmodern libssh-dev

## additional python packages
RUN easy_install pandocfilters

## Install plink
RUN cd /tmp && wget -q https://www.cog-genomics.org/static/bin/plink150727/plink_linux_x86_64.zip && unzip plink_linux_x86_64.zip && cp plink /usr/local/bin/

## Install multivariate plink
RUN cd /tmp && wget -q --no-check-certificate https://genepi.qimr.edu.au/staff/manuelF/multivariate/plink.multivariate && chmod +x plink.multivariate && cp plink.multivariate /usr/local/bin/

## Install additional R packages
RUN Rscript -e "biocLite(c('sparcl', 'illuminaHumanv3.db', 'pander', 'ggdendro', 'sp', 'topGO', 'gdata', 'affy', 'vsn', 'limma', 'sva', 'scatterplot3d', 'pushoverr', 'SNPlocs.Hsapiens.dbSNP142.GRCh37', 'MatrixEQTL', 'plsdepot', 'TxDb.Hsapiens.UCSC.hg19.knownGene'))"
RUN Rscript -e "devtools::install_github('jimhester/knitrBootstrap', ref='rmarkdown_template')"
RUN Rscript -e "devtools::install_github('gabraham/plink2R/plink2R')"

## Add basic instruction to display for interactive containers
COPY config/message.txt /etc/motd
RUN echo "cat /etc/motd" >> /etc/bash.bashrc

## Configure RStudio server
COPY config/r.profile /tmp/.Rprofile
RUN echo 'cp /tmp/.Rprofile /home/$USER/' >> /usr/bin/userconf.sh

## control access to websites
COPY config/access.conf /etc/nginx/conf.d/access.conf
COPY config/access.conf /etc/rstudio/ip-rules

## Add additional programs to run at startup
COPY config/supervisored.conf /tmp/
RUN cat /tmp/supervisored.conf >> /etc/supervisor/conf.d/supervisord.conf

## Add the raw data to the image
COPY data/ /analysis/data/

## Add R and pandoc files
COPY heatshock_analysis.* /analysis/
COPY include/ /analysis/include/
COPY html/ /analysis/html/

## Create directories for temporary and log files
RUN mkdir /analysis/tmp && mkdir /analysis/log

## additional user configuration
ENV USER=rstudio
RUN echo chown -R '$USER' /usr/share/nginx/html >> /usr/bin/userconf.sh && echo chown -R '$USER' /analysis >> /usr/bin/userconf.sh

WORKDIR /analysis/
