#!/usr/bin/env Rscript

library(knitr)
library(knitrBootstrap)

htmlRoot <- "/var/www/html"
file.copy("html/waiting.html", file.path(htmlRoot, "index.html"), overwrite=TRUE)

logs <- list(knitr=list(dir="/analysis/log", file="analysis.log", 
				desc="Main log file with knitr output", name="knitr"),
		snp=list(dir="/analysis/log", file="hapmap_yri.snp_flt.log",
				desc="PLINK log file for SNP QC", name="SNP QC"),
		sample=list(dir="/analysis/log", file="hapmap_yri.smpl_flt.log",
				desc="PLINK log file for sample genotype QC", name="sample QC"),
		mds=list(dir="/analysis/log", file="hapmap_yri.smpl_flt2.log",
				desc="PLINK log file for exclusion of samples and MDS plot",
				name="MDS"))

data <- list(exprRaw=list(dir="/analysis/tmp", file="heatshock_expr_raw.tab.gz",
				desc="Probe intensities for all samples and probes that pass QC",
				name="probe intensities"),
		expr=list(dir="/analysis/tmp", file="heatshock_expr_norm.tab.gz",
				desc="Normalised gene expression estimates for all samples and probes that pass QC",
				name="gene expression"),
		geno=list(dir="/analysis/tmp", file="yri_geno.tar.gz",
				desc="Genotypes for all samples and SNPs that pass QC",
				name="genotypes (PLINK)"))

copyFiles <- function(files, dest){
	if(!file.exists(dest)) dir.create(dest)
	for(i in 1:length(files)){
		source <- file.path(files[[i]]$dir, files[[i]]$file)
		if(file.exists(source))
			file.copy(source, file.path(dest, files[[i]]$file))
	}
}

linkLog <- function(log,format=c("markdown", "html")){
	linkFile(log, "log", format)
}

linkFile <- function(file, dest, format=c("markdown", "html")){
	format <- match.arg(format)
	if(format == "markdown")
		paste0("[", file$name, "](", dest, "/", file$file, ")")
	else if(format == "html")
		paste0("<a href=\"", dest, "/", file$file, "\">", file$name, "</a>")
}

includeLogs <- function(logs, format=c("markdown", "html")){
	format <- match.arg(format)
	logs <- logs[sapply(logs, function(x) file.exists(file.path(x$dir, x$file)))]
	df <- data.frame(log=sapply(logs, linkLog, format), 
			description=sapply(logs, "[[", "desc"))
	kable(df, format=format, row.names=FALSE)
}

## create config entry for one format block
formatConfigSection <- function(config){
	out <- character()
	config <- config[!is.na(config)]
	out <- paste(names(config), config, sep=":")
	out <- gsub("\n", "\n  ", out)
	out <- unlist(strsplit(out, "\n"))
	out
}

## Create apandoc config file for use with knitr
writeConfig <- function(config, file){
	out <- apply(config, 1, formatConfigSection)
	con <- file(file, open="w")
	on.exit(close(con))
	for(block in out){
		writeLines(block, con=con)
		cat("\n", file=con)
	}
}

pandocBootstrap <- function(input, format, config = getOption('config.pandoc'), ext = NA,
                  encoding = getOption('encoding')) {
  if(!is.null(config)){
  	if(file.exists(config)){
  		config <- read.dcf(config)
  	} else{
  		config <- read.dcf(textConnection(config))
  	}
  	parNames <- colnames(config)
  	if (length(parNames) && 'format' %in% parNames) {
    	warning("Field 'format' in configuration renamed to 't'")
    	colnames(config)[parNames == 'format'] <-'t'
  	}
  	if("t" %in% parNames && "bootstrap" %in% config[,"t"]){
  		bootParam <- config[which(config[,"t"] %in% c("bootstrap", "") | is.na(config[,"t"])), , drop=FALSE]
  		bootIdx <- which(bootParam[, "t"] == "bootstrap")
  		bootParam[bootIdx, "t"] <- "html5"
  		header <- knitrBootstrap:::create_header()
  		if("H" %in% colnames(bootParam)){
			if(!is.na(bootParam[bootIdx, "H"])){
  				header <- paste(bootParam[bootIdx,"H"], header, sep="\\n")
			}
			bootParam[bootIdx, "H"] <- header
  		} else {
			headerCol <- as.character(rep(NA, nrow(bootParam)))
			headerCol[bootIdx] <- header
  			bootParam <- cbind(bootParam, H=headerCol)	
  		}
  		config <- config[which(config[,"t"] != "bootstrap"), , drop=FALSE]
  	}
  	
  	if(missing(format) || is.null(format) || format != "html5" && (nrow(config) && any(!is.na(config[, "t"])))){
  		configFile <- tempfile("pandocCfg")
  		writeConfig(config, file=configFile)
  		knitr::pandoc(input, format, config=configFile, ext=ext, encoding=encoding)
  	}
  	if(nrow(bootParam)){
  		bootFile <- tempfile("bootCfg")
  		writeConfig(bootParam, file=bootFile)
  		knitr::pandoc(input, format, config=bootFile, ext=ext, encoding=encoding)
  	}
  }
}

for(file in c("heatshock_analysis.md", "heatshock_analysis.html", "heatshock_analysis.pdf")){
	if(file.exists(file)) file.remove(file)
}
tryCatch(
		knit("heatshock_analysis.Rmd"),
		error=function(e){
			cat("# We have a problem!", "R encountered the following issue while trying",
					"to analise the heat shock data:", "<p class=\"errorMessage\">",
					e$message, "</p>", "## Log files", includeLogs(logs, "markdown"), 
					sep="\n", 
					file="heatshock_analysis.md")
		}
)

tryCatch(
		pandocBootstrap("heatshock_analysis.md", config="default.pandoc"),
		error=function(e){
			cat("<!DOCTYPE html>", "<html>", "<head>", '<meta charset="UTF-8">',
					"<title>Pandoc error</title>","</head>", "<body>", 
					"<h1>We have a problem!</h1>", 
					"<p>Pandoc encountered a problem while trying to generate the analysis report.</p>",
					"<p class=\"errorMessage\">", e$message, "</p>",
					"<h2>Log files</h2>",
					includeLogs(logs, "html"),
					"</body>","</html>", sep="\n", file="heatshock_analysis.html")
		},
		finally={
			file.copy("heatshock_analysis.html", file.path(htmlRoot, "index.html"),
					overwrite=TRUE)
			copyFiles(logs, file.path(htmlRoot, "log"))
			copyFiles(data, file.path(htmlRoot, "data"))
			if(file.exists("heatshock_analysis.pdf")){
				file.copy("heatshock_analysis.pdf", 
						file.path(htmlRoot, "heatshock_analysis.pdf"),
						overwrite=TRUE)
			}
		}
)
