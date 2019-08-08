#!/usr/bin/env Rscript

# These functions use the sratoolkit to download fastq files associated with GEOME metadata
# that have been queried via `queryMetadata()`` function in FimsUtils.R. They require sratoolkit
# to have been downloaded. The user can either add them to the $PATH or supply a path
# to the functions.

#' Download or convert fastq data from NCBI Sequence Read Archive using multiple threads
#' 
#' `fasterqDump()` uses the SRAtoolkit command-line function `fasterq-dump` to download fastq
#' files from all samples returned by a [queryMetadata()] query of GEOME, when one of the
#' entities queried was `fastqMetadata`
#' 
#' The `fasterq-dump` tool uses temporary files and multi-threading to speed up the extraction of FASTQ from SRA-accessions.
#' This function works best with sratoolkit functions of version 2.9.6 or greater. \href{https://www.ncbi.nlm.nih.gov/sra/docs/toolkitsoft/}{SRAtoolkit} functions can (ideally)
#' be in your $PATH, or you can supply a path to them using the sratoolkitPath argument.
#' `fasterqDump()` downloads files to the current working directory unless a different one is assigned through outputDirectory.
#' Change the number of threads by adding "-e X" to arguments where X is the number of threads
#' `fasterq-dump` will automatically split paired-end data into three files with:
#'  file_1.fastq having read 1
#'  file_2.fastq having read 2
#'  file.fastq having unmatched reads
#' `fasterqDump()` can then rename these files based on their materialSampleID and locality.
#' Note that `fasterq-dump` will store temporary files in ~/ncbi/public/sra by default unless
#' you pass "-t /path/to/temp/dir" to arguments. \emph{Make sure to periodically delete these temporary files.}
#' 
#' @param queryMetadata_object A list object returned from `queryMetadata` where one of the 
#'  entities queried was `fastqMetadata`.
#' @param sratoolkitPath String. A path to a local copy of sratoolkit. Only necessary if sratoolkit
#'  is not on your $PATH. Assumes executables are inside `bin`.
#' @param outputDirectory String. A path to the directory where you would like the files to be stored.
#' @param arguments A string variable of arguments to be passed directly to `fasterq-dump`.
#' Defaults to "-p" to show progress. Use fasterqDumpHelp = TRUE to see a list of arguments.
#' @param filenames String. How would you like the downloaded fastq files to be named?  
#' "accessions" names files with SRA accession numbers
#' "IDs" names files with their materialSampleID
#' "locality_IDs" names files with their locality and materialSampleID.
#' @param source String. `fasterq-dump` can retrieve files directly from SRA, or it can convert .sra files
#'  previously downloaded with `prefetch` that are in the current working directory. 
#'  "sra" downloads from SRA
#'  "local" converts .sra files in the current working directory.
#' @param cleanup Logical. cleanup = T will delete any intermediate .sra files.
#' @param fasterqDumpHelp Logical. fasterqDumpHelp = T will show the help page for `fasterq-dump` and then quit.
#' 
#' @return This function will not return anything within r. It simply downloads fastq files. It will print command line
#' stdout to the console, and also provide a start and end time and amount of time elapsed during the download.
#' @seealso \url{https://www.ncbi.nlm.nih.gov/sra/docs/toolkitsoft/} to download pre-compiled executables for sratoolkit or
#' \url{https://github.com/ncbi/sra-tools/wiki/Building-and-Installing-from-Source>} to install from source
#' 
#' This function will not work on Windows systems because fasterq-dump is not currently available for Windows. 
#' See \code{\link{fastqDump()}} if you use Windows. See \code{\link{prefetch()}} to download .sra files prior to converting them locally.
#' 
#' 
#' @examples
#' \donttest{
#' # Run a query of GEOME first
#' acaoli <- queryMetadata(entity = "fastqMetadata", 
#' query = "genus = Acanthurus AND specificEpithet = olivaceus AND _exists_:bioSample", select=c("Event"))
#' 
#' #trim to 3 entries for expediency
#' acaoli$fastqMetadata<-acaoli$fastqMetadata[1:3,]
#' acaoli$Event<-acaoli$Event[1:3,]
#' 
#' # Download straight from SRA, naming files with their locality and materialSampleID
#' fasterqDump(queryMetadata_object = acaoli, filenames = "IDs", source = "sra")
#' 
#' # A generally faster option is to run prefetch first, followed by fasterqDump, with cleanup = T to remove the 
#' # prefetched .sra files.
#' prefetch(queryMetadata_object = acaoli)
#' fasterqDump(queryMetadata_object = acaoli, filenames = "IDs", source = "local", cleanup = T)
#' }
#' @export
fasterqDump <-function(queryMetadata_object, sratoolkitPath = "", outputDirectory = "./", arguments = "-p", filenames = "accessions", source = "sra",cleanup = FALSE, fasterqDumpHelp = FALSE) {
  
  if(fasterqDumpHelp == TRUE){
    if(sratoolkitPath != ""){
      system(command = paste(file.path(sratoolkitPath,"bin","fasterq-dump"), "--help"))
    }
    else{
      system(command = paste("fasterq-dump","--help"))
    }
    stop("Showing fasterq-dump help and quitting")
  }
  
  # get a start time
  start<-Sys.time()
  print(paste("Start:", start))
  
  #check if fastqMetadata table is present
  if(is.null(queryMetadata_object$fastqMetadata)){
    stop(paste(queryMetadata_object,"does not have any fastq metadata. Retry your query with select = c('fastqMetadata')"))
  }
  
  runAccessions <- queryMetadata_object$fastqMetadata$bioSample$experiment$runAccessions
  
  #download from SRA
  if(source == "sra"){ 
    for(accession_number in runAccessions){
      print(accession_number)
      if(sratoolkitPath != ""){
        system(command = paste(file.path(sratoolkitPath,"bin","fasterq-dump"),accession_number,"-O",outputDirectory, arguments))
      }
      else{
        system(command = paste("fasterq-dump",accession_number,"-O",outputDirectory, arguments))
      }
    } 
  }
  #operate on local files
  if(source == "local"){ 
    for(accession_number in runAccessions){
      print(accession_number)
      if(sratoolkitPath != ""){
        system(command = paste(file.path(sratoolkitPath,"bin","fasterq-dump"),paste(accession_number,".sra",sep=""),"-O",outputDirectory, arguments))
      }
      else{
        system(command = paste("fasterq-dump",paste(accession_number,".sra",sep=""),"-O",outputDirectory, arguments))
      }
      
    } 
  }
#Rename files based on materialSampleID if the user requests
  if(filenames == "IDs"){
    for(file in list.files(path=outputDirectory, pattern=".fastq")){
      #if the accession number part of the filename is NOT in the queryMetadata_object, skip it
      if(!(strsplit(file,".",fixed=T)[[1]][1] %in% runAccessions)){next}
      ID <- queryMetadata_object$fastqMetadata$identifier[which(runAccessions == strsplit(file,".", fixed=T)[[1]][1])]
      filename<-sub(pattern = ".sra", replacement = "", x = file, fixed=T)
      filename<-sub(pattern = "[A-Z]{3}[0-9]+([12_]*\\.[a-z]+)",replacement = paste0(ID,"\\1"), filename, perl=T)
      print(paste("Renaming",file,"to",filename))
      file.rename(from = file.path(outputDirectory,file), to = file.path(outputDirectory,filename))
    }
  }
  
  #Rename files based on locality AND materialSampleID if the user requests
  if(filenames == "locality_IDs"){
    #check if Event table is present
    if(is.null(queryMetadata_object$fastqMetadata)){
      stop(paste(queryMetadata_object,"does not have any Event metadata. Retry your query with select = c('Event'), or rename with just IDs" ))
    }
    for(file in list.files(path=outputDirectory, pattern=".fastq")){
      #if the accession number part of the filename is NOT in the queryMetadata_object, skip it
      if(!(strsplit(file,".",fixed=T)[[1]][1] %in% runAccessions)){next}
      locality_ID <- paste(queryMetadata_object$Event$locality[which(runAccessions == strsplit(file,".", fixed=T)[[1]][1])], queryMetadata_object$fastqMetadata$identifier[which(runAccessions == strsplit(file,".", fixed=T)[[1]][1])], sep = "_")
      filename<-sub(pattern = ".sra", replacement = "", x = file, fixed=T)
      filename<-sub(pattern = "[A-Z]{3}[0-9]+([12_]*\\.[a-z]+)",replacement = paste0(locality_ID,"\\1"), filename, perl=T)
      print(paste("Renaming",file,"to",filename))
      file.rename(from = file.path(outputDirectory,file), to = file.path(outputDirectory,filename))
    }
  }
  
#Rename files with just the accession number, removing the ".sra"
  if(filenames == "accessions"){
    for(file in list.files(path=outputDirectory, pattern=".fastq")){  
      #if the accession number part of the filename is NOT in the queryMetadata_object, skip it
      if(!(strsplit(file,".",fixed=T)[[1]][1] %in% runAccessions)){next}
      filename<-sub(pattern = ".sra", replacement = "", x = file, fixed=T)
      filename<-sub(pattern = "([A-Z]{3}[0-9]+[12_]*)\\.[a-z]+",replacement = paste0("\\1",".fastq"), filename, perl=T)
      print(paste("Renaming",file,"to",filename))
      file.rename(from = file.path(outputDirectory,file), to = file.path(outputDirectory,filename))
    }
  }  
  
  if(cleanup == TRUE){
    for(r in runAccessions){
      print(paste("Deleting",paste(r,".sra",sep="")))
      file.remove(file.path(outputDirectory,paste(r,".sra", sep="")))
    }
  }
  
  #get an end time and measure the length of the run
  end <- Sys.time()
  print(paste("Finish:", end))
  print(end - start)
  
}





#' Download or convert fastq data from NCBI Sequence Read Archive in a single thread (Windows compatible)
#' 
#' `fastqDump()` uses the SRAtoolkit command-line function `fastq-dump` to download fastq
#' files from all samples returned by a [queryMetadata()] query of GEOME, when one of the
#' entities queried was `fastqMetadata`
#' 
#' This function works best with sratoolkit functions of version 2.9.6 or greater. \href{https://www.ncbi.nlm.nih.gov/sra/docs/toolkitsoft/}{SRAtoolkit} functions can (ideally)
#' be in your $PATH, or you can supply a path to them using the sratoolkitPath argument.
#' `fastqDump()` downloads files to the current working directory unless a different one is assigned through outputDirectory.
#' 
#' `fastq-dump` will automatically split paired-end data into three files with:
#'  file_1.fastq having read 1
#'  file_2.fastq having read 2
#'  file.fastq having unmatched reads
#' `fastqDump()` can then rename these files based on their materialSampleID and locality.
#' 
#' @param queryMetadata_object A list object returned from `queryMetadata` where one of the 
#'  entities queried was `fastqMetadata`.
#' @param sratoolkitPath String. A path to a local copy of sratoolkit. Only necessary if sratoolkit
#'  is not on your $PATH. Assumes executables are inside `bin`.
#' @param outputDirectory String. A path to the directory where you would like the files to be stored.
#' @param arguments A string variable of arguments to be passed directly to `fastq-dump`.
#' Defaults to "-v --split 3" to show progress and split paired-end data. 
#' Use fastqDumpHelp = TRUE to see a list of arguments.
#' @param filenames String. How would you like the downloaded fastq files to be named?  
#' "accessions" names files with SRA accession numbers
#' "IDs" names files with their materialSampleID
#' "locality_IDs" names files with their locality and materialSampleID.
#' @param source String. `fastq-dump` can retrieve files directly from SRA, or it can convert .sra files
#'  previously downloaded with `prefetch` that are in the current working directory. 
#'  "sra" downloads from SRA
#'  "local" converts .sra files in the current working directory.
#' @param cleanup Logical. cleanup = T will delete any intermediate .sra files.
#' @param fastqDumpHelp Logical. fastqDumpHelp = T will show the help page for `fastq-dump` and then quit.
#' 
#' @return This function will not return anything within r. It simply downloads fastq files. It will print command line
#' stdout to the console, and also provide a start and end time and amount of time elapsed during the download.
#' @seealso \url{https://www.ncbi.nlm.nih.gov/sra/docs/toolkitsoft/} to download pre-compiled executables for sratoolkit or
#' \url{https://github.com/ncbi/sra-tools/wiki/Building-and-Installing-from-Source>} to install from source
#' 
#' See \code{\link{prefetch()}} to download .sra files prior to converting them locally. This two step process works faster than
#' just using `fastqDump()`.
#' See \code{\link{fasterqDump()}} for a faster, multithreaded version of `fastqDump()` that does not work on Windows.
#' 
#' 
#' @examples
#' \donttest{
#' # Run a query of GEOME first
#' acaoli <- queryMetadata(entity = "fastqMetadata", 
#' query = "genus = Acanthurus AND specificEpithet = olivaceus AND _exists_:bioSample", select=c("Event"))
#' 
#' #trim to 3 entries for expediency
#' acaoli$fastqMetadata<-acaoli$fastqMetadata[1:3,]
#' acaoli$Event<-acaoli$Event[1:3,]
#' 
#' # Download straight from SRA, naming files with their locality and materialSampleID
#' fastqDump(queryMetadata_object = acaoli, filenames = "locality_IDs", source = "sra")
#' 
#' # A generally faster option is to run prefetch first, followed by fastqDump, with cleanup = T to remove the 
#' # prefetched .sra files.
#' prefetch(queryMetadata_object = acaoli)
#' fastqDump(queryMetadata_object = acaoli, filenames = "IDs", source = "local", cleanup = T)
#' }
#' @export
fastqDump <-function(queryMetadata_object, sratoolkitPath = "", outputDirectory = ".", arguments = "-v --split-3", filenames = "accessions", source = "sra", cleanup = FALSE, fastqdumpHelp = FALSE) {

    if(fastqdumpHelp == TRUE){
      if(sratoolkitPath != ""){
        system(command = paste(file.path(sratoolkitPath,"bin","fastq-dump"),"--help"))
      }
      else{
        system(command = paste("fastq-dump","--help")) 
      }
      stop("Showing fastq-dump help and quitting")
        
    }
    #check if fastqMetadata table is present
    if(is.null(queryMetadata_object$fastqMetadata)){
      stop(paste(queryMetadata_object,"does not have any fastq metadata. Retry your query with select = c('fastqMetadata')"))
    }
  
    # get a start time
    start<-Sys.time()
    print(paste("Start:", start))

    runAccessions <- queryMetadata_object$fastqMetadata$bioSample$experiment$runAccessions
    
    #download from SRA
    if(source == "sra"){ 
      for(accession_number in runAccessions){
        print(accession_number)
        if(sratoolkitPath != ""){
          system(command = paste(file.path(sratoolkitPath,"bin","fastq-dump"),accession_number,"-O",outputDirectory, arguments))
          }
        else{
          system(command = paste("fastq-dump",accession_number,"-O",outputDirectory, arguments))
        }
      }  
    }
    #operate on local files
    if(source == "local"){ 
      for(accession_number in runAccessions){
        print(accession_number)
        if(sratoolkitPath != ""){
          system(command = paste(file.path(sratoolkitPath,"bin","fastq-dump"),paste(accession_number,".sra",sep=""),"-O",outputDirectory, arguments))
        }
        else{
          system(command = paste("fastq-dump",paste(accession_number,".sra",sep=""),"-O",outputDirectory, arguments))
        }
      } 
    }


    #Rename files based on materialSampleID if the user requests
    if(filenames == "IDs"){
      for(file in list.files(path=outputDirectory, pattern=".fastq")){
        #if the accession number part of the filename is NOT in the queryMetadata_object, skip it
        if(!(strsplit(file,".",fixed=T)[[1]][1] %in% runAccessions)){next}
        ID <- queryMetadata_object$fastqMetadata$identifier[which(runAccessions == strsplit(file,".", fixed=T)[[1]][1])]
        filename<-sub(pattern = ".sra", replacement = "", x = file, fixed=T)
        filename<-sub(pattern = "[A-Z]{3}[0-9]+([12_]*\\.[a-z]+)",replacement = paste0(ID,"\\1"), filename, perl=T)
        print(paste("Renaming",file,"to",filename))
        file.rename(from = file.path(outputDirectory,file), to = file.path(outputDirectory,filename))
      }
    }
    
    #Rename files based on locality AND materialSampleID if the user requests
    if(filenames == "locality_IDs"){
      #check if Event table is present
      if(is.null(queryMetadata_object$fastqMetadata)){
        stop(paste(queryMetadata_object,"does not have any Event metadata. Retry your query with select = c('Event'), or rename with just IDs" ))
      }
      for(file in list.files(path=outputDirectory, pattern=".fastq")){
        #if the accession number part of the filename is NOT in the queryMetadata_object, skip it
        if(!(strsplit(file,".",fixed=T)[[1]][1] %in% runAccessions)){next}
        locality_ID <- paste(queryMetadata_object$Event$locality[which(runAccessions == strsplit(file,".", fixed=T)[[1]][1])], queryMetadata_object$fastqMetadata$identifier[which(runAccessions == strsplit(file,".", fixed=T)[[1]][1])], sep = "_")
        filename<-sub(pattern = ".sra", replacement = "", x = file, fixed=T)
        filename<-sub(pattern = "[A-Z]{3}[0-9]+([12_]*\\.[a-z]+)",replacement = paste0(locality_ID,"\\1"), filename, perl=T)
        print(paste("Renaming",file,"to",filename))
        file.rename(from = file.path(outputDirectory,file), to = file.path(outputDirectory,filename))
      }
    }
    
    #Rename files with just the accession number, removing the ".sra"
    if(filenames == "accessions"){
      for(file in list.files(path=outputDirectory, pattern=".fastq")){  
        #if the accession number part of the filename is NOT in the queryMetadata_object, skip it
        if(!(strsplit(file,".",fixed=T)[[1]][1] %in% runAccessions)){next}
        filename<-sub(pattern = ".sra", replacement = "", x = file, fixed=T)
        filename<-sub(pattern = "([A-Z]{3}[0-9]+[12_]*)\\.[a-z]+",replacement = paste0("\\1",".fastq"), filename, perl=T)
        print(paste("Renaming",file,"to",filename))
        file.rename(from = file.path(outputDirectory,file), to = file.path(outputDirectory,filename))
      }
    }  
    
    if(cleanup == TRUE){
      for(r in runAccessions){
        print(paste("Deleting",paste(r,".sra",sep="")))
        file.remove(paste(r,".sra", sep=""))
      }
    }
  
    #get an end time and measure the length of the run
    end <- Sys.time()
    print(paste("Finish:", end))
    print(end - start)
}



#' Download data from NCBI Sequence Read Archive in .sra format using FASP or HTTPS protocols
#' 
#' `prefetch()` uses the SRAtoolkit command-line function `prefetch` to download .sra
#' files from all samples returned by a [queryMetadata()] query of GEOME, when one of the
#' entities queried was `fastqMetadata`
#' 
#' This function works best with SRAtoolkit functions of version 2.9.6 or greater. \href{https://www.ncbi.nlm.nih.gov/sra/docs/toolkitsoft/}{SRAtoolkit} functions can (ideally)
#' be in your $PATH, or you can supply a path to them using the sratoolkitPath argument.
#' It downloads files to the current working directory unless a different one is assigned through outputDirectory.
#' `prefetch` will automatically use the Fast and Secure Protocol (FASP) in the \href{https://downloads.asperasoft.com/connect2/}{Aspera Connect}
#' package if the `ascp` executable is in your $PATH. Otherwise it will use HTTPS.
#' You can alternatively pass the path to `ascp` by using arguments="-a path/to/ascp"
#' 
#' @param queryMetadata_object A list object returned from `queryMetadata` where one of the 
#'  entities queried was `fastqMetadata`.
#' @param sratoolkitPath String. A path to a local copy of sratoolkit. Only necessary if sratoolkit
#'  is not on your $PATH. Assumes executables are inside `bin`.
#' @param outputDirectory String. A path to the directory where you would like the files to be stored.
#' @param arguments A string variable of arguments to be passed directly to `prefetch`.
#' Defaults to "-p 1" to show progress.
#' Use prefetchHelp = TRUE to see a list of arguments.
#' @param prefetchHelp Logical. prefetchHelp = T will show the help page for `prefetch` and then quit.
#' 
#' @return This function will not return anything within r. It simply downloads .sra files. It will print command line
#' stdout to the console, and also provide a start and end time and amount of time elapsed during the download.
#' @seealso \url{https://www.ncbi.nlm.nih.gov/sra/docs/toolkitsoft/} to download pre-compiled executables for sratoolkit or
#' \url{https://github.com/ncbi/sra-tools/wiki/Building-and-Installing-from-Source>} to install from source
#' 
#' Use `prefetch` in combination with \code{\link{fastqDump()}} or \code{\link{fasterqDump()}} to convert .sra files to .fastq.
#' 
#' 
#' @examples
#' \donttest{
#' # Run a query of GEOME first
#' acaoli <- queryMetadata(entity = "fastqMetadata", 
#' query = "genus = Acanthurus AND specificEpithet = olivaceus AND _exists_:bioSample", select=c("Event"))
#' 
#' #trim to 3 entries for expediency
#' acaoli$fastqMetadata<-acaoli$fastqMetadata[1:3,]
#' acaoli$Event<-acaoli$Event[1:3,]
#' 
#' 
#' prefetch(queryMetadata_object = acaoli)
#' 
#' fastqDump(queryMetadata_object = acaoli, filenames = "IDs", source = "local", cleanup = T)
#' }
#' @export
prefetch <-function(queryMetadata_object, sratoolkitPath = "", outputDirectory = ".", arguments = "-p 1", prefetchHelp = FALSE) {
  
  if(prefetchHelp == TRUE){
    if(sratoolkitPath != ""){
      system(command = paste(file.path(sratoolkitPath,"bin", "prefetch"),"--help"))
    }
    else{
      system(command = paste("prefetch", "--help"))
    }
    stop("Showing prefetch help and quitting")
  }
  
  # get a start time
  start<-Sys.time()
  print(paste("Start:", start))
  
  if(is.null(queryMetadata_object$fastqMetadata)){
    stop(paste(queryMetadata_object,"does not have any fastq metadata"))
  }
  
  for(accession_number in queryMetadata_object$fastqMetadata$bioSample$experiment$runAccessions){
    print(accession_number)
    if(sratoolkitPath != ""){
      system(command = paste(file.path(sratoolkitPath,"bin","prefetch"),accession_number,"-O",outputDirectory, arguments))
    }
    else{
    system(command = paste("prefetch",accession_number,"-O",outputDirectory, arguments))
    }
  } 
  
  #get an end time and measure the length of the run
  end <- Sys.time()
  print(paste("Finish:", end))
  print(end - start)
}





