#!/usr/bin/env Rscript

# Make sure RCurl package is loaded
library(RCurl)

# Function to fetch FIMS data from service using ARK Identifier
# Uses RCurl (libcurl) to fetch so we can follow re-directs
# assumes there is a header and it is tab delimited
graphData <- function(url) {
  return (read.delim(textConnection(getURLContent(url,followLocation=TRUE)),header=TRUE,sep="\t"))
}
