#!/usr/bin/env Rscript

library(knitr)

file.copy("html/waiting.html", "/usr/share/nginx/html/index.html", overwrite=TRUE)

for(file in c("heatshock_analysis.md", "heatshock_analysis.html", "heatshock_analysis.pdf")){
	if(file.exists(file)) file.remove(file)
}
tryCatch(
		knit("heatshock_analysis.Rmd"),
		error=function(e){
			cat("# We have a problem!", "R encountered the following issue while trying",
					"to analise the heat shock data:", e, sep="\n", 
					file=heatshock_analysis.md)
		}
)

tryCatch(
		pandoc("heatshock_analysis.md", config="default.pandoc"),
		error=function(e){
			cat("<!DOCTYPE html>", "<html>", "<head>", '<meta charset="UTF-8">',
					"<title>Pandoc error</title>","</head>", "<body>", 
					"<h1>We have a problem!</h1>", 
					"<p>Pandoc encountered a problem while trying to generate the analysis report.</p>",
					"<p>", e, "</p>",
					"</body>","</html>", sep="\n", file="heatshock_analysis.html")
		},
		finally={
			file.copy("heatshock_analysis.html", "/usr/share/nginx/html/index.html",
					overwrite=TRUE)
			if(file.exists("heatshock_analysis.pdf")){
				file.copy("heatshock_analysis.pdf", 
						"/usr/share/nginx/html/heatshock_analysis.pdf",
						overwrite=TRUE)
			}
		}
)
