#!/usr/bin/env Rscript

# This is a utility script to query the GeOMe-db database for analysis in R

fimsRestRoot <- "https://api.geome-db.org"
#fimsRestRoot <- "http://localhost:8080"
fimsProjectsUrl <- paste(fimsRestRoot, "projects", sep="/")
fimsExpeditionsUrl <- paste(fimsRestRoot, "projects", "_projectId_", "expeditions", sep="/")
fimsNetworkConfigUrl <- paste(fimsRestRoot, "network", "config", sep="/")
fimsProjectConfigUrl<- paste(fimsRestRoot, "projects", "_projectId_", "config", sep="/")
fimsQueryUrl <- paste(fimsRestRoot, "records", "_entity_", "json", sep="/")
fimsFastaQueryUrl <- paste(fimsRestRoot, "records", "fastaSequence", "fasta", sep="/")

#' Get a list of projects in GEOME
#' @examples
#' \dontrun{
#' projects <- listProjects()
#' }
#' @export
listProjects <- function() {

    r <- httr::GET(fimsProjectsUrl)
    stop_for_status(r)

    projects <- list()

    for (p in httr::content(r)) {
        projects[[length(projects) + 1]] <- list(id=p$projectId, title=p$projectTitle)
    }

    return(projects)
}

#' Get a list of expeditions for a GEOME project
#' @param projectId The project to list expeditions for.
#' @examples
#' \dontrun{
#' expeditions <- listExpeditions(projectId)
#' }
#' @export
listExpeditions <- function(projectId) {

    r <- httr::GET(gsub("_projectId_", projectId, fimsExpeditionsUrl))
    stop_for_status(r)

    expeditions <- list()

    for (e in httr::content(r)) {
        expeditions[[length(expeditions) + 1]] <- list(code=e$expeditionCode, title=e$expeditionTitle)
    }

    return(expeditions)
}

#' Get a list of entities (i.e. tables) available to query
#' @param projectId   (optional) The project to fetch entities for. If not provided, the network entities will be returned.
#' @examples
#' \dontrun{
#' entities <- listEntities(projectId)
#' entities <- listEntities()
#' }
#' @export
listEntities <- function(projectId=NA) {
    if (is.na(projectId)) {
        r <- httr::GET(fimsNetworkConfigUrl)
    } else {
        r <- httr::GET(gsub("_projectId_", projectId, fimsProjectConfigUrl))
    }
    stop_for_status(r)

    entities <- list()

    for (e in httr::content(r)$entities) {
        entities[[length(entities) + 1]] <- e$conceptAlias
    }

    return(entities)
}

#' Get a list of loci that are stored in FASTA format directly in GEOME (not in the SRA)
#' @examples
#' \dontrun{
#' markers <- listLoci()
#' }
#' @export
listLoci <- function() {

    r <- httr::GET(fimsNetworkConfigUrl)
    stop_for_status(r)

    markers <- list()

    for (l in httr::content(r)$lists) {
        if (l$alias == 'markers') {
            for (f in l$fields) {
                markers[[length(markers) + 1]] <- f$value
            }
        }
    }

    return(markers)
}

#' Query metadata from the GEOME database.
#' 
#' `queryMetadata` uses HTTP to query metadata from the GEOME database. If you are looking to download associated
#' sequences from the SRA, you must include 'fastqMetadata' as one of the entities searched (this is done by default)
#' and you should include "_exists_:bioSample" within your query statement to find only samples with associated SRA
#' sequences
#'
#' @param entity      The entity or entities (tables) to query. Multiple entities can be given as a vector.
#'  One or more of ('Event', 'Sample', 'Tissue', 'Sample_Photo', 'Event_Photo','fastqMetadata'). Default is to include 'Samples'
#' @param projects    list of projects to include in the query. The default is all projects
#' @param expeditions Only applicable if projects are specified. list of expeditions to include in the query. The default is all expeditions
#' @param select      list of entites to include in the response. The @param `entity` will always be included in the response. `fastqMetadata`
#'                    included by default.
#' @param source      list of column names to include in the data.frame results. If there is no entity prefix, the column
#'                    is assumed to belong to the @param `entity`.
#'                    Ex. list('Event.eventID', 'Event.locality', 'materialSampleID', 'bcid', 'Event.bcid')
#'                          'materialSampleID' and 'bcid' in the above list are assumed to belong to the @param `entity`
#' @param query       FIMS Query statement \url{http://fims.readthedocs.io/en/latest/fims/query.html} query string.
#'                    Ex. 'yearCollected >= 2017 and country = "Indonesia"'. Your query must include "_exists_:bioSample"
#'                    to find samples that have associated data in the SRA.
#' @param page        The results page to return. Used to offset the page for large result sets. Defaults to 0.
#' @param limit       The number of results to include in the response. Defaults to 10000
#' @return a list object with each entity (table) as a dataframe object
#' @examples
#' \dontrun{
#' df <- queryMetadata('Sample', projects=list(1), expeditions=list("acaach_CyB_JD", "acajap_CyB_JD"))
#' df <- queryMetadata('Sample', names=list("materialSampleID", "bcid"), query="Chordata")
#' df <- queryMetadata('Sample', projects=list(1), expeditions=list("acajap_CyB_JD"),
#'                     names=list("bcid"), query="yearCollected=2008")
#' df <- queryMetadata('Sample', select=list('Event', 'Tissue'), names=list("bcid"),
#'                     query="yearCollected=2008")
#' df <- queryMetadata('fastqMetadata', select=list('Event', 'Sample', 'Tissue'),
#'                     query="_exists_:bioSample")
#' acaoli <- queryMetadata(entity = "fastqMetadata", 
#'           query = "genus = Acanthurus AND specificEpithet = olivaceus AND _exists_:bioSample", select=c("Event"))
#' }
#' @export
queryMetadata <- function(entity = "Sample", projects=list(), expeditions=list(), select=list("fastqMetadata"), query="", source=NULL, page=0, limit="10000") {
    query.string <- prepareQueryString(projects, expeditions, select, query)

    if (!is.null(source)) {
        source = paste(source, collapse=",")
    }
   
    r <- httr::GET(gsub("_entity_", entity, fimsQueryUrl), query=list(q = query.string, limit=format(limit, scientific = FALSE), page=format(page, scientific = FALSE), source=source))

    stop_for_status(r)
    if (httr::status_code(r) == 204) {
        print("No Records Found")
    } else {

        resp <- httr::content(r, as='text')
        results <- jsonlite::fromJSON(resp)$content

        if (length(results[[entity]]) == limit) {
            print("More results available. Run the query again, incrementing the page variable")
        }

        return(results)
    }
}

#' Query Sanger sequences directly from the GEOME database
#' 
#' For Sanger sequence data (typically of mitochondrial origin), it is possible to store the sequence directly within GEOME.
#' `querySanger()` allows you to download this sequence data into a DNAbin object, as well as to your working directory as a
#' FASTA-formatted file.
#'
#' @param locus      the locus to fetch. list of markers can be found by calling `listLoci()`
#' @param projects    list of projects to include in the query. The default is all projects
#' @param expeditions Only applicable if projects are specified. list of expeditions to include in the query. The default is all expeditions
#' @param query       FIMS Query DSL \url{http://fims.readthedocs.io/en/latest/fims/query.html} query string.
#'                    Ex. 'yearCollected >= 2017 and country = "Indonesia"'
#' @return a DNAbin object, which is a fairly standard form for storing DNA data in binary format. It will also download
#' a FASTA-formatted file to your working directory.
#' @examples
#' \dontrun{
#' data <- querySanger(locus = 'CYB', projects=list(1), expeditions=list("acaach_CyB_JD", "acajap_CyB_JD"),
#'                      query="yearCollected >= 2008")
#'  
#' data <- querySanger(locus = 'CO1', query = "genus = Linckia AND specificEpithet = laevigata" )
#' }
#' @export
querySanger <- function(locus, projects=list(), expeditions=list(), query="") {
    query.string <- prepareQueryString(projects, expeditions, list(), query)

    if (nchar(query.string) > 0 && query.string != '*') {
        query.string <- paste0("(", query.string, ") AND ", 'fastaSequence.marker = ', locus)
    } else {
        query.string <- paste0('fastaSequence.marker = ', locus)
    }
    
    r <- httr::GET(fimsFastaQueryUrl, query=list(q = query.string))

    stop_for_status(r)

    if (httr::status_code(r) == 204) {
        print("No Samples Found")
    } else {

        fileResponse <- httr::GET(httr::content(r)$url)

        stop_for_status(fileResponse)

        temp <- tempfile()

        writeBin(httr::content(fileResponse, "raw"), temp)

        filename <- paste0(locus, ".fasta")
        utils::unzip(temp, files=filename)

        if (file.info(filename)$size == 0) {
            print("no fasta sequences found")
            return()
        }

	# returns output as a list
        return(ape::read.FASTA(filename))
    }
}

stop_for_status <- function(r) {
    if (httr::http_error(r)) {
        print(httr::content(r)$usrMessage)
        httr::stop_for_status(r)
    }
}


prepareQueryString <- function(projects, expeditions, select, query) {
    if (length(projects) > 0) {
        # create a queryString of the form "_projects_:[1,2]" including each projectId in list
        p <- paste0('_projects_:[', paste(projects, collapse=','), ']')
        if (trimws(query) == '') {
            query <- p
        } else {
            query <- paste0(p, " AND ", query)
        }

        if (length(expeditions) > 0) {
            # create a queryString of the form "_expeditions_:["test", "test1"]" including each expeditionCode in list
            e <- paste0('_expeditions_:[', paste(expeditions, collapse=','), ']')
            query <- paste0(e, " AND ", query)
        }
    }

    if (length(select) > 0) {
        s <- paste0('_select_:[', paste(select, collapse=','), ']')
        query <- paste0(s, " ", query)
    }
    if (trimws(query) == '') {
        return("*")
    }

    return(query)
}