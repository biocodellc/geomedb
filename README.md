# fimsR-access
A set of R scripts for accessing and working with FIMS data from R

Big Gaps in this package:
1) Currently only return FIMS Metadata, not sequences 
2) Currently can only filter the results by expeditionCode, will add more query functionality soon

Installation of FIMSR-access package from github
```
install.packages("devtools")
library(devtools)
install_github("dipnet/fimsR-access")
library(fims)
```

Now, to use the FIMS package in R you need to at least authenticate, obtaining the username and password from the project administrator:
```
authenticate("user", "pass")
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
df <- queryMetadata(names=list("materialSampleID", "bcid"), filters=list("_all"="Chordata")
```

The following query will the return "materialSampleID" and "bcid" columns for the samples in "TEST" expeditions where "yearCollected" = 2008
```
df <- queryMetadata(expeditions=list("TEST"), names=list("materialSampleID", "bcid"), filters=list(yearCollected="2008")
```

The following will fetch "CO1" fasta sequences and return a DNABin 
```
fasta <- queryFasta("C01", expeditions=list("TEST"), filters=list(yearCollected="2008")
```

You can fetch a list of expeditionCodes that are available to query:
```
expeditionsList <- listExpeditions()
```

You can fetch a list of the current fasta marker types:
```
markers <- listMarkers()
```




 
