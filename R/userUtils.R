#!/usr/bin/env Rscript

# BETA!
# This utility script is a set of functions available to users who must authenticate to access functions
# This script is not fully tested.  In particular, the cookies in curl aspect i haven't
# gotten to work all the way.

# Make RCurl package is loaded


# Location of login URL
fimsLoginServiceURL <- "http://biscicol.org/id/authenticationService/login"

# Set your cookies file, may need to adjust
cookies_file <- "/tmp/cookies.txt"


# Must call this first!
# authenticate, necessary to fetch data which is private
authenticate <- function(user,pass,pProject_id) {
  library(RCurl)
  library(jsonlite)
  curl <- getCurlHandle()
  opts <- curlSetOpt(cookiejar=cookies_file, curl=curl)
  postdata <- postForm(fimsLoginServiceURL,
           username=user,
           password=pass,
           style="POST",
           curl=curl,
           multipart=FALSE)

    # Return an object containing variables
    fimsVars = list(
    project_id=pProject_id,
    user=user
  )
  return(fimsVars)
}

# Get a list of Dipnet graphs
listProjectGraphs <- function(vars) {
  # this URL returns all the graphs for the DIPNet project
  project_graphs_url <- paste("http://biscicol.org/id/projectService/graphs/",vars$project_id,sep="")
  # Get the all of the graphs of this project, coming back as JSON
  graphsJson <- getURLContent(project_graphs_url,followLocation=TRUE,cookiefile=cookies_file)
  graphVec <<- jsonlite::fromJSON(graphsJson)
  graphFrame <<- data.frame(graphVec)
  arks <- graphFrame[4]
  return(arks)
}

# Concatenate all Project graphs into one big graph
concatenateProjectGraphs <- function(vars) {
  graphs <- listProjectGraphs(vars)
  #mytempdata
  counter <- 1
  sumlength <- length(graphs$data.ark)
  for (thisgraph in graphs$data.ark) {
    # ensure resolution service is pre-pended onto ARK
    graphURI <- paste("http://n2t.net/",thisgraph,sep="")

    # informational message
    cat("fetching",thisgraph,"(",counter, "of",sumlength,")","\n")

    if (counter == 1) {
      mytempdata <- graphData(graphURI)
    } else {
      mytempdata <- merge(mytempdata, graphData(graphURI),all=TRUE)
    }

    # TESTING
    #if (counter == 3) {
    #  return(mytempdata)
    #}

    counter <- counter + 1
  }
  return(mytempdata)
}

# Function to fetch FIMS data from service using ARK Identifier
# Uses RCurl (libcurl) to fetch so we can follow re-directs
# assumes there is a header and it is tab delimited
#
# parameter: url = ark identifier with resolver (e.g. http://n2t.net/ark:/21547/lN2)
graphData <- function(url) {
  graph <-read.delim(textConnection(RCurl::getURLContent(url,followLocation=TRUE)),header=TRUE,sep="\t")
 # hard-code some column names
  mysub<-subset(graph,,
                 select = c(materialSampleID,principalInvestigator,locality,decimalLatitude,decimalLongitude,genus,species)
                )
  return(mysub)
}
