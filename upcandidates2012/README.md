# Data on religion and politics in India 

## upcandidates2012

This table contains a list of candidates and their likely religion for the 2012 Vidhan Sabha election in Uttar Pradesh, guessed with the [name2community](https://github.com/raphael-susewind/name2community) algorithm.

## Variables

name | description
--- | ---
id | unique code for each row, in case one ever needs it
ac_id_09 | ID code of the assembly segment assigned by the Election Commission (identical with all other post-delimitation codes, hence the _09)
candidate_*_name_12 | Name of the candidate running for party *
candidate_*_religion_12 | Likely religion of the candidate running for party * (note that this is just a "best bet" based on the social connotations of the candidate's name, not a fact-checked statement!)
candidate_*_religion_certainty_12 | Certainty index of likely religion of the candidate running for party * (a measure to eliminate false matches; see README of the  [name2community](https://github.com/raphael-susewind/name2community) algorithm)

## Raw data

Raw data was originally downloaded from http://eci.nic.in/ECI_Main/StatisticalReports/candidatewise/AE2012_8913.xls on May 27, 2013 as an Excel file; it was manually converted into candidates-2012.csv, processed using guesscommunity.pl to add likely religion estimates, and then prepared for inclusion into the dataset using transform.pl.

## License

While the database in its entirety is subject to an [ODC Open Database License](http://opendatacommons.org/licenses/odbl/), as explained in the main [README](https://github.com/raphael-susewind/india-religion-politics/blob/master/README.md) and [LICENSE](https://github.com/raphael-susewind/india-religion-politics/blob/master/LICENSE.md) files, the content of this specific table is partly factual data and partly experimental, and as such only subject to a simple [ODC Database Contents License](http://opendatacommons.org/licenses/dbcl/). Code used for compilation is subject to a [CC-BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) license.
