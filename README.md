
# geome-db

[![Build Status](https://travis-ci.org/biocodellc/fimsR-access.svg?branch=master)](https://travis-ci.org/biocodellc/fimsR-access)

"geomedb" is an R package for querying metadata and associated genetic sequences from GEOME

 The Genomic Observatory Metadatabase (GEOME Database) is an open access repository for geographic and ecological metadata associated with sequenced samples. This package is used to retrieve GeOMe data for analysis. See [here](http://www.geome-db.org) for more information regarding GeOMe.
 
The geomedb package provides functions for querying GEOME directly, as well as wrappers for [sratoolkit](https://www.ncbi.nlm.nih.gov/sra/docs/toolkitsoft/) executables. When used together, it is possible to download all metadata relevant to your query from GEOME and then download all associated SRA sequences.


## Installation
To get the current released version from [CRAN](https://CRAN.R-project.org/package=geomedb) :
```
install.packages("geomedb")
```

To get the current development version from github:
```
install.packages("devtools")
library(devtools)
install_github("biocodellc/fimsR-access")
library(geomedb)
```

## Usage

To get a list of projects in the database:

```{r}
project <- listProjects()
```

To get a list of expeditions for a project:

```{r}
expeditions <- listExpeditions(1)
```

To get a list of entities available to query in geome:

```{r}
entities <- listEntities()
```

To get a list of entities available to query for a specific project:

```{r}
entities <- listEntities(1)
```

The query function will execute a query against the [GeOMe](https://geome-db.org) database. The results are returned as a data.frame
The most basic query will return all the samples in the database:

```{r}
df <- queryMetadata('Sample')
```

The following query will return all samples for the expeditions "acaach_CyB_JD" and "acajap_CyB_JD"

```{r}
df <- queryMetadata('Sample', projects=list(1), expeditions=list("acaach_CyB_JD", "acajap_CyB_JD"))
```

The following query will the return "materialSampleID" and "bcid" columns for all samples.

```{r}
df <- queryMetadata('Sample', source=list("materialSampleID", "bcid"))
```

The following query will the return "materialSampleID", "bcid" and "eventID" columns for all samples and "eventID" and "locality" for all events related to the samples.

```{r}
df <- queryMetadata('Sample', select=list("Event"), source=list("materialSampleID", "bcid", "eventID", "Event.eventID", "Event.locality"))
```

The following query will the return "materialSampleID" and "bcid" columns for all samples where a full text search matches "Chordata"

```{r}
df <- queryMetadata('Sample', source=list("materialSampleID", "bcid"), query="Chordata")
```

The following query will the return "materialSampleID" and "bcid" columns for the samples in "acaach_CyB_JD" expeditions where "yearCollected" = 2008

```{r}
df <- queryMetadata('Sample', projects=list(1), expeditions=list("acaach_CyB_JD"), source=list("materialSampleID", "bcid"), query="yearCollected=2008")
```

The following query will the return all fastqMetadata and related tissues, samples, and events which have an SRA (bioSample) accession number attached.

```{r}
df <- queryMetadata("fastqMetadata", select=list("Event", "Sample", "Tissue"), query="_exists_:bioSample")
```

The following will fetch "CYB" fasta sequences and return a DNABin 

```{r}
fasta <- querySanger('CYB')
```

The following will fetch "CYB" fasta sequences for the expeditions "acaach_CyB_JD" and "acajap_CyB_JD" collected after 2007 and return a DNABin 

```{r}
fasta <- querySanger('CYB', projects=list(1), expeditions=list("acaach_CyB_JD", "acajap_CyB_JD"), query="yearCollected >= 2008")
```

This query will fetch all CO1 data for *Linckia laevigata*

```{r}
data <- querySanger(locus = 'CO1', query = "genus = Linckia AND specificEpithet = laevigata" )
```

You can fetch a list of the current loci types:
```{r}
markers <- listLoci()
```

Query only samples that have associated bioSamples in the SRA

```{r}
 acaoli_sra <- queryMetadata(entity = "fastqMetadata", 
 query = "genus = Acanthurus AND specificEpithet = olivaceus AND _exists_:bioSample", select=c("Event","Sample"))
```
Fetch SRA files that match the above query and then convert them into fastq files. (This could be done in one step with `fasterqDump` or `fastqDump` but it is slower)

```{r}
prefetch(queryMetadata_object = acaoli)

 fasterqDump(queryMetadata_object = acaoli, filenames = "IDs", source = "local", cleanup = T)
 ```

## Example

 Inggat is working on Orangebar Tang (\emph{Acanthurus olivaceus}) in the Philippines, and would like to download any genetic data
 that may be available in GEOME from previous research.
 
 First, she searches for all GEOME samples of this species.
 
```{r}
  acaoli <- queryMetadata(entity = "Sample", query = "genus = Acanthurus AND specificEpithet = olivaceus")
          
```
 
 Seeing that there are 787 samples in the database, mostly from the DIPnet project (projectID = 1), she decides to
 exclude any samples that are not from that project. She then downloads all data from Sanger-sequenced mitochondrial Cytochrome B into
 a DNAbin object as well as a FASTA file in her working directory.
 
```{r}
 

 acaoli_seqs <- querySanger(projects = 1, marker = "CYB", query = "genus = Acanthurus AND specificEpithet = olivaceus")
 
```
 
 Then she repeats her query for samples that are associated with massively parallel sequencing reads in the SRA.

```{r}
 
 acaoli_sra <- queryMetadata(entity = "fastqMetadata", 
 query = "genus = Acanthurus AND specificEpithet = olivaceus AND _exists_:bioSample", select=c("Event","Sample"))
 
```
 
 This query returns a list object with three data frames representing entities (tables) in GEOME: 'fastqMetadata'
 contains metadata from the SRA, 'Samples' contains metadata about the samples, and 'Events' contains metadata about
 the sampling events that obtained the samples. By including "_exists_:bioSample" in her query, Inggat selected only
 samples that have associated SRA data (biosamples).
 
 Inggat now uses `prefetch` to download .sra files for these samples that she has queried into her working directory.
 She then uses fasterqDump to convert these .sra files into fastq files, and rename them based on their original
 materialSampleID that the previous author supplied, and uses `cleanup = T` to delete the .sra files.
 

 
```{r}
 
 prefetch(queryMetadata_object = acaoli)

 fasterqDump(queryMetadata_object = acaoli, filenames = "IDs", source = "local", cleanup = T)
```
 
  This two-step approach is generally faster, but Inggat could also have simply used `fasterqDump()` to download fastq files directly from the SRA. If she has [Aspera Connect](https://downloads.asperasoft.com/connect2/) installed, with the ascp executable in her $PATH, her download would be even faster. If she was using Windows, she would have used `fastqDump()`, which is single-threaded. 
 
 

