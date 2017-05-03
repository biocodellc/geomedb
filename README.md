# geome-db
A set of R scripts for accessing and working with geome-db FIMS data from R

Installation of geome_db package from CRAN
```
install.packages("geomedb")
```

The query function will execute a query against the fims database. The results are returned as a data.frame
The most basic query will return all the samples in the database:
```
df <- queryMetadata()
```

The following query will return all samples for the expeditions "TEST" and "TEST2"
```
df <- queryMetadata(expeditions=list("TEST", "TEST2"))
```

The following query will the return "materialSampleID" and "bcid" columns for all samples.
```
df <- queryMetadata(names=list("materialSampleID", "bcid"))
```

The following query will the return "materialSampleID" and "bcid" columns for all samples where a full text search matches "Chordata"
```
df <- queryMetadata(names=list("materialSampleID", "bcid"), query="Chordata")
```

The following query will the return "materialSampleID" and "bcid" columns for the samples in "TEST" expeditions where "yearCollected" = 2008
```
df <- queryMetadata(expeditions=list("TEST"), names=list("materialSampleID", "bcid"), query="+yearCollected:2008")
```

The following will fetch "CO1" fasta sequences and return a DNABin 
```
fasta <- queryFasta("C01", expeditions=list("TEST"), query="+yearCollected:2008")
```

You can fetch a list of expeditionCodes that are available to query:
```
expeditionsList <- listExpeditions()
```

You can fetch a list of the current fasta marker types:
```
markers <- listMarkers()
```

### Development
Installation of geome_db package from github
```
install.packages("devtools")
library(devtools)
install_github("dipnet/fimsR-access")
library(geomedb)
```



 
