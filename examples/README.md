# Data on religion and politics in India 

## examples

**Note (September 2026):** these examples are kept for the record. They reproduce the published analyses only approximately, and they inherit the issues documented in [KNOWN-ISSUES.md](../KNOWN-ISSUES.md). epa2017.sql contained a syntax error (13 missing commas) until version 1.1. The R and GRASS toolchain used by epa2017.R and epa2017.sh (GRASS 6.4, spgrass6, rgdal) can no longer be installed. kolkata.sql needs a regular-expression extension for SQLite and refers to the wbid table.

This folder contains example SQL queries, R scripts and other processing tools that can be used to replicate some of the papers that have used this dataset. The papers themselves are referenced below; to create the replication data, one has to run the respective sql file against the main database, and then continue with either a statistical script or by using the respective vrt file to produce maps with appropriate GIS software (e.g. QGIS plus TileMill). Short explanations can usually be found in the respective *.txt files.

## Files

name | reference
--- | ---
epa2017.* | Susewind, R. (2017). Muslims in Indian cities: degrees of segregation and the elusive 'ghetto'. Environment and Planning A
epw2014.* | Susewind, R., & Dhattiwala, R. (2014). [Spatial variation in the 'Muslim vote' in Gujarat and Uttar Pradesh, 2014](http://pub.uni-bielefeld.de/publication/2694099). Economic & Political Weekly, 49 (39), 99–110
samaj2015.* | Susewind, R., & Taylor, C. (2015). [Islamicate Lucknow today: historical legacy and urban aspirations](http://dx.doi.org/10.4000/samaj.3911). South Asia Multidisciplinary Academic Journal, 11 , 1–42
kolkata.* | Booth-level extraction for Kolkata (not tied to a publication)

## License

All content in this folder is subject to a [CC-BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) license.
