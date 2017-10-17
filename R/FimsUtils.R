#!/usr/bin/env Rscript

# This is a utility script to query the Geome-db FIMS database for analysis in R

# CONSTANTS
projectId <- 25

fimsRestRoot <- "http://www.geome-db.org/rest"
fimsProjectExpeditionsUrl <- paste(fimsRestRoot, "projects", projectId, "expeditions", sep="/")
#fimsQueryUrl <- paste(fimsRestRoot, "projects", "query", "csv", sep="/")
fimsQueryUrl <- paste(fimsRestRoot, "projects", "query", "fastq", sep="/")
fimsFastaQueryUrl <- paste(fimsRestRoot, "projects", "query", "fasta", sep="/")
fimsFastaMarkersUrl <- paste(fimsRestRoot, "projects", projectId, "config", "lists", "markers", "fields", sep="/")

#' get a list of expeditions to query against
#' @examples
#' \dontrun{
#' expeditions <- listExpeditions()
#' }
#' @export
listExpeditions <- function() {

    r <- httr::GET(fimsProjectExpeditionsUrl)
    httr::stop_for_status(r)

    expeditions <- list()

    for (e in httr::content(r)) {
        expeditions[[length(expeditions) + 1]] <- e$expeditionCode
    }

    return(expeditions)
}

#' get a list of markers to query against
#' @examples
#' \dontrun{
#' markers <- listMarkers()
#' }
#' @export
listMarkers <- function() {

    r <- httr::GET(fimsFastaMarkersUrl)
    httr::stop_for_status(r)

    markers <- list()

    for (f in httr::content(r)) {
        markers[[length(markers) + 1]] <- f$value
    }

    return(markers)
}

#' fetch the FimsMetadata from the geome-db database
#'
#' @param expeditions list of expeditions to include in the query. The default is all expeditions
#' @param names       list of column names to include in the data.frame results
#' @param query       FIMS Query DSL \url{http://fims.readthedocs.io/en/latest/fims/query.html} query string.
#'                    Ex. '+locality:fuzzy +country:"exact phrase"'
#' return: a dataframe object
#' @examples
#' \dontrun{
#' df <- queryMetadata(expeditions=list("TEST", "TEST2"))
#' df <- queryMetadata(names=list("materialSampleID", "bcid"), query="Chordata")
#' df <- queryMetadata(expeditions=list("TEST"), names=list("bcid"), query="+yearCollected:2008")
#' }
#' @export
queryMetadata <- function(expeditions=list(), query="", names=NULL) {
    query.string <- prepareQueryString(expeditions, query)

    r <- httr::GET(fimsQueryUrl, query=list(q = query.string))

    httr::stop_for_status(r)

    if (httr::status_code(r) == 204) {

        print("No Samples Found")

    } else {

        fileResponse <- httr::GET(httr::content(r)$url)

        httr::stop_for_status(fileResponse)

        df <- utils::read.csv(text=httr::content(fileResponse, "text", encoding = "ISO-8859-1"))

        if (!is.null(names)) {
            df.names = names(df)
            df.remove = list()

            for (name in names) {
                if (!is.element(name, df.names)) {
                    stop(paste("The given column name (", name, ") does not exist in the query results"))
                }
            }

            for (col in df.names) {
                if (!is.element(col, names)) {
                    df[[col]] <- NULL
                }
            }
        }

        return(df)
    }
}

prepareQueryString <- function(expeditions, query) {

    if (length(expeditions) > 0) {
        expedition.names <- rep("expedition", length(expeditions))
        # create a queryString of the form "+expedition:{expeditionCode}" including each expeditionCode in list
        expedition.params <- paste0("+", expedition.names, ":", expeditions, collapse=" ")
        query <- paste0(query, " ", expedition.params)
    }

    return(query)
}


#' fetch Fasta sequences from the geome-db database
#'
#' @param marker      the marker to fetch
#' @param expeditions list of expeditions to include in the query. The default is all expeditions
#' @param query       FIMS Query DSL \url{http://fims.readthedocs.io/en/latest/fims/query.html} query string.
#'                    Ex. '+locality:fuzzy +country:"exact phrase"'
#' return: a DNAbin object, which is a fairly standard form for storing DNA data in binary format
#' @examples
#' \dontrun{
#' fasta <- queryFasta("C01", expeditions=list("TEST"), query="+yearCollected:2008")
#' }
#' @export
queryFasta <- function(marker, expeditions=list(), query="") {
    query.string <- prepareQueryString(expeditions, query)

    if (nchar(query.string) > 0) {
        query.string <- paste0(query.string, " ", '+fastaSequence.marker:"', marker, '"')
    } else {
        query.string <- paste0(query.string, '+fastaSequence.marker:"', marker, '"')
    }

    r <- httr::GET(fimsFastaQueryUrl, query=list(q = query.string))

    httr::stop_for_status(r)

    if (httr::status_code(r) == 204) {

        print("No Samples Found")

    } else {

        fileResponse <- httr::GET(httr::content(r)$url)

        httr::stop_for_status(fileResponse)

        temp <- tempfile()

        writeBin(httr::content(fileResponse, "raw"), temp)

        utils::unzip(temp, files="geome-db-output.fasta")

        if (file.info("geome-db-output.fasta")$size == 0) {
            print("no fasta sequences found")
            return()
        }

	# returns output as a list
        return(ape::read.FASTA("geome-db-output.fasta"))
    }
}
