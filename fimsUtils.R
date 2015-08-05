#!/usr/bin/env Rscript

# BETA! 
# This utility script is a set of functions available to users who must authenticate to access functions
# This script is not fully tested.  In particular, the cookies in curl aspect i haven't
# gotten to work all the way.



# Make RCurl package is loaded
library(RCurl)
library(jsonlite)

# Set your cookies file, may need to adjust
cookies_file <- "/tmp/cookies.txt"

# authenticate, necessary to fetch data which is private
authenticate <- function(user,pass) {
  curl <- getCurlHandle()
  opts <- curlSetOpt(cookiejar=cookies_file, curl=curl)
  postdata <- postForm("http://biscicol.org/id/authenticationService/login", 
           username=user,
           password=pass, 
           style="POST",
           curl=curl,
           multipart=FALSE)
}

# Get a list of Dipnet graphs
allDipnetGraphs <- function() {
  # this URL returns all the graphs for the DIPNet project
  # DIPNet project ID in FIMS is 25
  project_graphs_url <- "http://biscicol.org/id/projectService/graphs/25"
  # Get the all of the graphs of this project, coming back as JSON
  graphsJson <- getURLContent(project_graphs_url,followLocation=TRUE,cookiefile=cookies_file)
  graphVec <- fromJSON(graphsJson)
  graphFrame <- data.frame(graphVec)
  arks <- graphFrame[4]
  return(arks)
}
