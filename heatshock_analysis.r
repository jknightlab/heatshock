#!/usr/bin/env Rscript

library(rmarkdown)
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
	ans <- kable(df, format=format, row.names=FALSE)
  if(format == "html"){
    ans <- gsub("&lt;(/?a.*?)&gt;", "<\\1>", ans)
    ans <- gsub("&quot;", "\"", ans)
    ans <- gsub("<table>", "<table class=\"table table-hover\">", ans)
  }
  ans
}

for(file in c("heatshock_analysis.md", "heatshock_analysis.html", "heatshock_analysis.pdf")){
	if(file.exists(file)) file.remove(file)
}
tryCatch(
		render("heatshock_analysis.Rmd"),
		error=function(e){
			cat("<!DOCTYPE html>", "<html>", "<head>", '<meta charset="UTF-8">',
					"<title>Error</title>",
					"<script src=\"https://cdnjs.cloudflare.com/ajax/libs/jquery/2.0.3/jquery.min.js\"></script>",
  					"<script src=\"https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.11.3/jquery-ui.min.js\"></script>",
  					"<script src=\"https://netdna.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js\"></script>",
					"<link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css\">",
					"</head>", "<body>", 
					"<div id=\"wrap\"><div class=\"container\">",
					"<div class=\"page-header\"><h1>We have a problem!</h1></div>", 
					"<p>A problem occured while trying to generate the analysis report.</p>",
					"<div class=\"panel panel-danger\">", 
					"<div class=\"panel-heading\"><h4>Error message</h4></div>",	
					"<div class=\"panel-body\">",e$message, "</div></div>",
					"<h2>Log files</h2>",
					"The following log files were generated and may help in diagnosing the problem.",
					includeLogs(logs, "html"),
					"</div></div>",
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
