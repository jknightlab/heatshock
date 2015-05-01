#!/usr/bin/env Rscript

library(knitr)

htmlRoot <- "/var/www/html"
file.copy("html/waiting.html", file.path(htmlRoot, "index.html"), overwrite=TRUE)

logs <- list(knitr=list(dir="/analysis/log", file="analysis.log", 
				desc="Main log file with knitr output", name="knitr"),
		snp=list(dir="/analysis/log", file="hapmap_yri.snp_flt.log",
				desc="PLINK log file for SNP QC", name="SNP QC"),
		sample=list(dir="/analysis/log", file="hapmap_yri.smpl_flt.log",
				desc="PLINK log file for sample genotype QC", name="sample QC"))

copyLogs <- function(logs, dest){
	if(!file.exists(dest)) dir.create(dest)
	for(i in 1:length(logs)){
		source <- file.path(logs[[i]]$dir, logs[[i]]$file)
		if(file.exists(source))
			file.copy(source, file.path(dest, logs[[i]]$file))
	}
}

linkLog <- function(log,format=c("markdown", "html")){
	format <- match.arg(format)
	if(format == "markdown")
		paste0("[", log$name, "](log/", log$file, ")")
	else if(format == "html")
		paste0("<a href=log/", log$file, ">", log$name, "</a>")
}

includeLogs <- function(logs, format=c("markdown", "html")){
	format <- match.arg(format)
	logs <- logs[sapply(logs, function(x) file.exists(file.path(htmlRoot, "log", x$file)))]
	df <- data.frame(log=sapply(logs, linkLog, format), 
			description=sapply(log, "[[", "desc"))
	kable(df, format=format)
}

for(file in c("heatshock_analysis.md", "heatshock_analysis.html", "heatshock_analysis.pdf")){
	if(file.exists(file)) file.remove(file)
}
tryCatch(
		knit("heatshock_analysis.Rmd"),
		error=function(e){
			copyLogs(logs, file.path(htmlRoot, "log"))
			cat("# We have a problem!", "R encountered the following issue while trying",
					"to analise the heat shock data:", "<p class=\"errorMessage\">",
					e$message, "</p>", "## Log files", includeLogs(logs, "markdown"), 
					sep="\n", 
					file="heatshock_analysis.md")
		}
)

tryCatch(
		pandoc("heatshock_analysis.md", config="default.pandoc"),
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
			if(file.exists("heatshock_analysis.pdf")){
				file.copy("heatshock_analysis.pdf", 
						file.path(htmlRoot, "heatshock_analysis.pdf"),
						overwrite=TRUE)
			}
		}
)
