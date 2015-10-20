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

Now, to use the FIMS package in R you need to at least authenticate, obtaining the username and password from the project administrator:
```
auth<-authenticate("user","pass",25)
```

The most common request will likely be getting all the graphs into one.  This function loads all graphs from specified
project into one data.frame.  It will likely take some time but will give you the status as it is fetching data.  YOu will want to use some other function to cache the returned data so you don't need to do this too often.
```
allgraphs<-concatenateProjectGraphs(auth)
```




 
