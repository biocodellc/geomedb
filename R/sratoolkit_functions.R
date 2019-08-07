#!/usr/bin/env Rscript

# These functions use the sratoolkit to download fastq files associated with GEOME metadata
# that have been queried via queryMetadata() function in FimsUtils.R. They require sratoolkit
# to have been downloaded. The user can either add them to the $PATH or supply a path
# to the functions.

#' 
fasterqDump <-function(queryMetadata_object, sratoolkitPath = "", workingDirectory = "./", outputDirectory = "./", arguments = "-p", filenames = "accessions", source = "sra",cleanup = FALSE, fasterqDumpHelp = FALSE) {
  
  if(fasterqDumpHelp == TRUE){
    if(sratoolkitPath != ""){
      system(command = paste(file.path(sratoolkitPath,"bin","fasterq-dump"), "--help"))
    }
    else{
      system(command = paste("fasterq-dump","--help"))
    }
    stop("Showing fasterq-dump help and quitting")
  }
  
  #check if fastqMetadata table is present
  if(is.null(queryMetadata_object$fastqMetadata)){
    stop(paste(queryMetadata_object,"does not have any fastq metadata. Retry your query with select = c('fastqMetadata')"))
  }
  
  setwd(workingDirectory)
  
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
      filename<-sub(pattern = "[A-Z]+[0-9]+\\.*s*r*a*",replacement = ID, file, perl=T)
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
      filename<-sub(pattern = "[A-Z]+[0-9]+\\.*s*r*a*",replacement = locality_ID, file, perl=T)
      print(paste("Renaming",file,"to",filename))
      file.rename(from = file.path(outputDirectory,file), to = file.path(outputDirectory,filename))
    }
  }
  
#Rename files with just the accession number, removing the ".sra"
  if(filenames == "accessions"){
    for(file in list.files(path=outputDirectory, pattern=".fastq")){  
      #if the accession number part of the filename is NOT in the queryMetadata_object, skip it
      if(!(strsplit(file,".",fixed=T)[[1]][1] %in% runAccessions)){next}
      filename<-sub(pattern = "([A-Z]+[0-9]+)\\.*s*r*a*",replacement = "\\1", file, perl=T)
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
  
  }

fastqDump <-function(queryMetadata_object, sratoolkitPath = "", workingDirectory = ".", outputDirectory = ".", arguments = "-v --split-3", filenames = "accessions", source = "sra", cleanup = FALSE, fastqdumpHelp = FALSE) {

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
    
    setwd(workingDirectory)

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
        filename<-sub(pattern = "[A-Z]+[0-9]+\\.*s*r*a*",replacement = ID, file, perl=T)
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
        filename<-sub(pattern = "[A-Z]+[0-9]+\\.*s*r*a*",replacement = locality_ID, file, perl=T)
        print(paste("Renaming",file,"to",filename))
        file.rename(from = file.path(outputDirectory,file), to = file.path(outputDirectory,filename))
      }
    }
    
    #Rename files with just the accession number, removing the ".sra"
    if(filenames == "accessions"){
      for(file in list.files(path=outputDirectory, pattern=".fastq")){  
        #if the accession number part of the filename is NOT in the queryMetadata_object, skip it
        if(!(strsplit(file,".",fixed=T)[[1]][1] %in% runAccessions)){next}
        filename<-sub(pattern = "([A-Z]+[0-9]+).*s*r*a*",replacement = "\\1", file, perl=T)
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
  
}


prefetch <-function(queryMetadata_object, sratoolkitPath = "", workingDirectory = ".", outputDirectory = ".", arguments = "-p 1", prefetchHelp = FALSE) {
  
  if(prefetchHelp == TRUE){
    if(sratoolkitPath != ""){
      system(command = paste(file.path(sratoolkitPath,"bin", "prefetch"),"--help"))
    }
    else{
      system(command = paste("prefetch", "--help"))
    }
    stop("Showing prefetch help and quitting")
  }
  
  if(is.null(queryMetadata_object$fastqMetadata)){
    stop(paste(queryMetadata_object,"does not have any fastq metadata"))
  }
  
  setwd(workingDirectory)
  
  for(accession_number in queryMetadata_object$fastqMetadata$bioSample$experiment$runAccessions){
    print(accession_number)
    if(sratoolkitPath != ""){
      system(command = paste(file.path(sratoolkitPath,"bin","prefetch"),accession_number,"-O",outputDirectory, arguments))
    }
    else{
    system(command = paste("prefetch",accession_number,"-O",outputDirectory, arguments))
    }
  } 
  
}





