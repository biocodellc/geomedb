#!/usr/bin/env Rscript

# FIMS utility scripts that don't require one to be logged in

# Make sure RCurl package is loaded
library(RCurl)

# Function to fetch FIMS data from service using ARK Identifier
# Uses RCurl (libcurl) to fetch so we can follow re-directs
# assumes there is a header and it is tab delimited
#
# parameter: url = ark identifier with resolver (e.g. http://n2t.net/ark:/21547/lN2)
graphData <- function(url) {
  return (read.delim(textConnection(getURLContent(url,followLocation=TRUE)),header=TRUE,sep="\t"))
}
