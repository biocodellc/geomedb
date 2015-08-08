# fimsR-access
A set of R scripts for accessing and working with FIMS data from R

Big Gaps in this package:
1) Currently the FIMS only stores metadata and NOT sequences (will fix this soon).  
2) The function that fetches graphs uses a hard-coded list of column
names to fetch for (materialSampleID,principalInvestigator,locality,decimalLatitude,decimalLongitude,genus,species).  
(will fix this as well)

Installation of FIMSR-access package from github
```
install.packages("devtools")
library(devtools)
install_github("dipnet/fimsR-access")
library(fims)
```

You must first authenticate (obtain user/pass from project admin)
```
auth<-authentication("user","pass",25)
```

Get all graphs into one.  This function loads all graphs from specified
project into one data.frame
```
allgraphs<-concatenateProjectGraphs(auth)
```




 
