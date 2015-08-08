# fimsR-access
A set of R scripts for accessing and working with FIMS data from R

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




 
