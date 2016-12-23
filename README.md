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

The query function will execute a query against the fims database. It currently accepts a optional list of expeditionCodes to
filter the query with. The results are returned as a data.frame
```
df <- query(expeditions=list("TEST"))
```

You can fetch a list of expeditionCodes that are available to query:
```
expeditionsList <- listExpeditions()
```




 
