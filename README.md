# pathoscope2biom
------------------------------
An script to convert multiples pathoscope2 output in biom format

## Requisites

* R (tested in R v3.3.2)
* R libraries:
	* phyloseq
	* taxize
	* plyr
	* dplyr
	* biomformat

	
## Usage

	Rscript pathoscope2biom.R [path to pathoscope outputs] [pattern match to that files]

	Rscript pathoscope2biom.R ~/Desktop/pathoscope/outpus *.tsv
	
	