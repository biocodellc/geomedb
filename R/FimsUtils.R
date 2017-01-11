#!/usr/bin/env Rscript

# BETA!
# This is a utility script for DIPNet users to query the FIMS database for analysis in R

# CONSTANTS
projectId <- 25

fimsRestRoot <- "http://biscicol.org/dipnet/rest"
fimsLoginServiceUrl  <- paste(fimsRestRoot, "authenticationService", "login", sep="/")
fimsProjectExpeditionsUrl <- paste(fimsRestRoot, "projects", projectId, "expeditions", sep="/")
fimsQueryUrl <- paste(fimsRestRoot, "projects", "query", "csv", sep="/")
fimsFastaQueryUrl <- paste(fimsRestRoot, "projects", "query", "fasta", sep="/")

#' Must call this first!
#' authenticate, necessary to fetch data which is private
#' @export
authenticate <- function(user, pass) {

    r <- httr::POST(fimsLoginServiceUrl,
            body=list(
                    username=user,
                    password=pass
                ),
            encode="form"
            )

    httr::stop_for_status(r)
}

#' get a list of expeditions to query against
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

#' fetch the FimsMetadata from the dipnet database
#'
#' @param expeditions list of expeditions to include in the query. The default is all expeditions
#' @param names       list of column names to include in the data.frame results
#' @param filters     list of "column name":"value" pairs to include in the query. The special column name "_all" will do
#'                    a full text search in all columns for the value
#' @export
queryMetadata <- function(expeditions=list(), filters=list(), names=NULL) {
    query.params <- prepareQueryParams(expeditions, filters)

    r <- httr::POST(fimsQueryUrl,
            body=I(query.params),
            encode="form",
            httr::content_type("application/x-www-form-urlencoded")
            )

    httr::stop_for_status(r)

    df <- read.csv(text=httr::content(r, "text", encoding = "ISO-8859-1"))

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

prepareQueryParams <- function(expeditions, filters) {
    query.params = ""

    if (length(expeditions) > 0) {
        expedition.names <- rep("expeditions", length(expeditions))
        # for each expeditionCode in list create a post param expeditions={expeditionCode} joining with &
        expedition.params <- paste0(expedition.names, "=", expeditions, collapse="&")
        query.params <- paste0(query.params, expedition.params)
    }

    if (length(filters) > 0) {
        # for each name in list create a post param name=value joining with &
        filter.params <- paste0(names(filters), "=", unname(filters), collapse="&")

        if (nchar(query.params) > 0) {
            query.params <- paste0(query.params, "&", filter.params)
        } else {
            query.params <- paste0(query.params, filter.params)
        }
    }
    return(query.params)
}


#' fetch Fasta sequences from the dipnet database
#'
#' @param marker      the marker to fetch
#' @param expeditions list of expeditions to include in the query. The default is all expeditions
#' @param filters     list of "column name":"value" pairs to include in the query. The special column name "_all" will do
#'                    a full text search in all columns for the value
#' @export
queryFasta <- function(marker, expeditions=list(), filters=list()) {
    query.params <- prepareQueryParams(expeditions, filters)

    if (nchar(query.params) > 0) {
        query.params <- paste0(query.params, "&", "fastaSequence.urn:marker=", marker)
    } else {
        query.params <- paste0(query.params, "fastaSequence.urn:marker=", marker)
    }

    r <- httr::POST(fimsFastaQueryUrl,
        body=I(query.params),
        encode="form",
        httr::content_type("application/x-www-form-urlencoded")
    )

    httr::stop_for_status(r)

    temp <- tempfile()

    writeBin(httr::content(r, "raw"), temp)

    unzip(temp, files="dipnet-fims-output.fasta")

    if (file.info("dipnet-fims-output.fasta")$size == 0) {
        print("no fasta sequences found")
        return()
    }

    return(adegenet::fasta2DNAbin("dipnet-fims-output.fasta"))
}