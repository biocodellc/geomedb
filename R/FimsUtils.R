#!/usr/bin/env Rscript

# BETA!
# This is a utility script for DIPNet users to query the FIMS database for analysis in R

# load necessary libraries
library(httr)

# CONSTANTS
projectId <- 25

fimsRestRoot <- "http://biscicol.org/dipnet/rest"
#fimsRestRoot <- "http://localhost:8080/dipnet/rest"
fimsLoginServiceUrl  <- paste(fimsRestRoot, "authenticationService", "login", sep="/")
fimsProjectExpeditionsUrl <- paste(fimsRestRoot, "projects", projectId, "expeditions", sep="/")
fimsQueryUrl <- paste(fimsRestRoot, "projects", "query", "csv", sep="/")

# Must call this first!
# authenticate, necessary to fetch data which is private
authenticate <- function(user, pass) {

    r <- POST(fimsLoginServiceUrl,
            body=list(
                    username=user,
                    password=pass
                ),
            encode="form"
            )

    stop_for_status(r)
}

# get a list of expeditions to query against
listExpeditions <- function() {

    r <- GET(fimsProjectExpeditionsUrl)
    stop_for_status(r)

    expeditions <- list()

    for (e in content(r)) {
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
query <- function(expeditions=list(), filters=list(), names=NULL) {
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

    r <- POST(fimsQueryUrl,
            body=I(query.params),
            encode="form",
            content_type("application/x-www-form-urlencoded")
            )

    stop_for_status(r)

    df <- read.csv(text=content(r, "text", encoding = "ISO-8859-1"))

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
