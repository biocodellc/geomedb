# geome-db
A set of R scripts for accessing and working with geome-db FIMS data from R

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

## Examples

To get a list of projects in the database:
```
project <- listProjects()
```

To get a list of expeditions for a project:
```
expeditions <- listExpeditions(1)
```

To get a list of entities available to query in geome:
```
entities <- listEntities()
```

To get a list of entities available to query for a specific project:
```
entities <- listEntities(1)
```

The query function will execute a query against the [GeOMe](https://geome-db.org) database. The results are returned as a data.frame
The most basic query will return all the samples in the database:
```
df <- queryMetadata('Sample')
```

The following query will return all samples for the expeditions "acaach_CyB_JD" and "acajap_CyB_JD"
```
df <- queryMetadata('Sample', projects=list(1), expeditions=list("acaach_CyB_JD", "acajap_CyB_JD"))
```

The following query will the return "materialSampleID" and "bcid" columns for all samples.
```
df <- queryMetadata('Sample', source=list("materialSampleID", "bcid"))
```

The following query will the return "materialSampleID", "bcid" and "eventID" columns for all samples and "eventID" and "locality" for all events related to the samples.
```
df <- queryMetadata('Sample', select=list("Event"), source=list("materialSampleID", "bcid", "eventID", "Event.eventID", "Event.locality"))
```

The following query will the return "materialSampleID" and "bcid" columns for all samples where a full text search matches "Chordata"
```
df <- queryMetadata('Sample', source=list("materialSampleID", "bcid"), query="Chordata")
```

The following query will the return "materialSampleID" and "bcid" columns for the samples in "acaach_CyB_JD" expeditions where "yearCollected" = 2008
```
df <- queryMetadata('Sample', projects=list(1), expeditions=list("acaach_CyB_JD"), source=list("materialSampleID", "bcid"), query="yearCollected=2008")
```

The following query will the return all fastqMetadata and related tissues, samples, and events which have an SRA (bioSample) accession number attached.
```
df <- queryMetadata("fastqMetadata", select=list("Event", "Sample", "Tissue"), query="_exists_:bioSample")
```

The following will fetch "CYB" fasta sequences and return a DNABin 
```
fasta <- queryFasta('CYB')
```

The following will fetch "CYB" fasta sequences for the expeditions "acaach_CyB_JD" and "acajap_CyB_JD" collected after 2007 and return a DNABin 
```
fasta <- queryFasta('CYB', projects=list(1), expeditions=list("acaach_CyB_JD", "acajap_CyB_JD"), query="yearCollected >= 2008")
```

You can fetch a list of the current fasta marker types:
```
markers <- listMarkers()
```
