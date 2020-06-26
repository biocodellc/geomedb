# geomedb 2.1

This release fixes some package check issues and broken documentation links

# geomedb 2.0

This release adds functionality for fetching fastq files in R from the SRA

* `listMarkers` renamed to `listLoci`
* `queryFasta` renamed to `querySanger`
* `fastqDump`: Download or convert fastq data from NCBI Sequence Read Archive in a single thread (Windows compatible)
* `fasterqDump`: Download or convert fastq data from NCBI Sequence Read Archive using multiple threads
* `prefetch`: Download data from NCBI Sequence Read Archive in .sra format using FASP or HTTPS protocols

# geomedb 1.0

This is a major release, which updates the package to work with the latest [GeOMe](https://geome-db.org) changes.

* queryMetadata: 
	* query across multiple project & all data in GeOMe
	* query syntax has changed and now resembles SQL
	* query results are returned for each entity. No longer a flat table representation
