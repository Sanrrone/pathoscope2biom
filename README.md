# pathoscope2biom
------------------------------
A script to convert multiple PathoScope2 output files to BIOM format

## Requisites

* R (tested in R v3.3.2)
* R libraries:
    * phyloseq
    * taxize
    * plyr
    * dplyr
    * biomformat

    
## Usage

    Rscript pathoscope2biom.R [path to pathoscope output] [matching pattern to files]

    Rscript pathoscope2biom.R example *.tsv
    