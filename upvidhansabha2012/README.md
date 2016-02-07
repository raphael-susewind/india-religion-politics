# Data on religion and politics in India 

## upvidhansabha2012

This table contains booth-level (form 20) results for the 2012 Vidhan Sabha election in Uttar Pradesh.

## Variables

name | description
--- | ---
id | unique code for each row, in case one ever needs it
ac_id_09 | ID code of the assembly segment assigned by the Election Commission (identical with all other post-delimitation codes, hence the _09)
booth_id_12 | ID code of the polling booth assigned by the Election Commission (together with ac_id_09, this should suffice for matching with other tables)
electors_12 | Number of registered electors
turnout_12 | Number of actual voters
turnout_percent_12 | turnout_12 divided by electors_12
male_votes_12 | Number of male voters
female_votes_12 | Number of female voters
female_votes_percent_12 | female_votes_12 divided by turnout_12
votes_*_12 | Number of votes polled by party *
votes_*_percent_12 | votes_*_12 divided by turnout_12

## Raw data

Originally, this data was crawled using download.pl on April 26, 2013 from http://ceouttarpradesh.nic.in/Form20.aspx.

The data came in excel files, which I manually copy-and-pasted into results.csv since the format differed too much for any automated solution. This file was then cleaned up and an SQL dump prepared through transform.pl for integration into the main database

## License

While the database in its entirety is subject to an [ODC Open Database License](http://opendatacommons.org/licenses/odbl/), as explained in the main [README](https://github.com/raphael-susewind/india-religion-politics/blob/master/README.md) and [LICENSE](https://github.com/raphael-susewind/india-religion-politics/blob/master/LICENSE.md) files, the content of this specific table is factual data, and as such only subject to a simple [ODC Database Contents License](http://opendatacommons.org/licenses/dbcl/). Code used for crawling and compilation is subject to a [CC-BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) license.
