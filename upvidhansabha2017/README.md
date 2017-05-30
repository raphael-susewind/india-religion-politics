# Data on religion and politics in India 

## upvidhansabha2017 - DRAFT

This table contains booth-level (form 20) results for the 2017 Vidhan Sabha election in Uttar Pradesh.

ATTENTION: This is a DRAFT table; I am sharing it with the explicit request to double check for potential errors - will remove this notice once I myself became surer of the quality of this data. You have been warned!

## Variables

name | description
--- | ---
id | unique code for each row, in case one ever needs it
ac_id_09 | ID code of the assembly segment assigned by the Election Commission (identical with all other post-delimitation codes, hence the _09)
booth_id_17 | ID code of the polling booth assigned by the Election Commission (together with ac_id_09, this should suffice for matching with other tables)
electors_17 | Number of registered electors
turnout_17 | Number of actual voters
turnout_percent_17 | turnout_17 divided by electors_17
male_votes_17 | Number of male voters
female_votes_17 | Number of female voters
female_votes_percent_17 | female_votes_17 divided by turnout_17
nota_17 | Count of NOTA option
tendered_17 | Number of tendered votes
votes_*_17 | Number of votes polled by party *
votes_*_percent_17 | votes_*_17 divided by turnout_17

## Raw data

Originally, this data was crawled using download.pl on May 8, 2017 from http://ceouttarpradesh.nic.in/Form20.aspx and then processed through transform.pl for integration into the main database. I am grateful to Yusuf Neggers from Brown for helping in cleaning the mess up...

## License

While the database in its entirety is subject to an [ODC Open Database License](http://opendatacommons.org/licenses/odbl/), as explained in the main [README](https://github.com/raphael-susewind/india-religion-politics/blob/master/README.md) and [LICENSE](https://github.com/raphael-susewind/india-religion-politics/blob/master/LICENSE.md) files, the content of this specific table is factual data, and as such only subject to a simple [ODC Database Contents License](http://opendatacommons.org/licenses/dbcl/). Code used for crawling and compilation is subject to a [CC-BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) license.
