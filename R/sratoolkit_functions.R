#!/usr/bin/env Rscript

# These functions use the sratoolkit to download fastq files associated with GEOME metadata
# that have been queried via queryMetadata() function in FimsUtils.R. They require sratoolkit
# to have been downloaded. The user can either add them to the $PATH or supply a path
# to the functions.


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







#Write paired end data into separate files, and unpaired data into a 3rd file
# by adding -3 to the list of arguments only if requested by user AND the library layout is "paired"
if(splitPairs == TRUE) {
  if(queryMetadata_object$fastqMetadata$libraryLayout[which(queryMetadata_object$fastqMetadata$bioSample$experiment$runAccession == accession_number)]=="paired"){
    split <- "-3"
  }}

split <- NULL

# Benchmarking
On late 2015 iMac with 3.1 GHz Intel Core i5, 16 GB memory, 4 cores
Downloading paired-end file with 7,992,378 reads per direction. 2.26 GB.

# Just fasterq-dump

m53e-303-26932:public cran5048$ time fasterq-dump SRR6473174 -p -o test
join   :|-------------------------------------------------- 100.00%
concat :|-------------------------------------------------- 100.00%
spots read      : 7,992,378
reads read      : 15,984,756
reads written   : 15,984,756


real	12m21.844s
user	2m48.474s
sys	0m13.722s

# prefetch without aspera connect followed by fasterq-dump
m53e-303-26932:public cran5048$ time prefetch SRR6473174

2019-07-12T21:00:21 prefetch.2.9.3: 1) Downloading 'SRR6473174'...
2019-07-12T21:00:21 prefetch.2.9.3:  Downloading via https...
2019-07-12T21:01:11 prefetch.2.9.3: 1) 'SRR6473174' was downloaded successfully
2019-07-12T21:01:11 prefetch.2.9.3: 'SRR6473174' has 0 unresolved dependencies

real	0m50.095s
user	0m3.971s
sys	0m2.429s


  m53e-303-26932:public cran5048$ time fasterq-dump SRR6473174 -p
join   :|-------------------------------------------------- 100.00%
concat :|-------------------------------------------------- 100.00%
spots read      : 7,992,378
reads read      : 15,984,756
reads written   : 15,984,756

real	4m59.680s
user	2m36.175s
sys	0m8.626s

So about 6 minutes total

# Using Aspera Connect

m53e-303-26932:public cran5048$ time prefetch SRR6473174 -p 1

2019-07-12T21:31:18 prefetch.2.9.3: 1) Downloading 'SRR6473174'...
2019-07-12T21:31:18 prefetch.2.9.3:  Downloading via fasp...
2019-07-12T21:31:44 prefetch.2.9.3:  fasp download succeed
2019-07-12T21:31:44 prefetch.2.9.3: 1) 'SRR6473174' was downloaded successfully
2019-07-12T21:31:44 prefetch.2.9.3: 'SRR6473174' has 0 unresolved dependencies

real	0m27.567s
user	0m0.901s
sys	0m1.598s

m53e-303-26932:public cran5048$ time fasterq-dump SRR6473174 -p
join   :|-------------------------------------------------- 100.00%
concat :|-------------------------------------------------- 100.00%
spots read      : 7,992,378
reads read      : 15,984,756
reads written   : 15,984,756

real	4m15.514s
user	2m24.998s
sys	0m8.254s

Conversion even went faster... not sure why...
