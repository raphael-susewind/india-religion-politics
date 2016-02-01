# Data on religion and politics in India 

## uploksabha2009

This table contains booth-level (form 20) results for the 2009 Lok Sabha election from Uttar Pradesh.

## Variables

name | description
--- | ---
id | unique code for each row, in case one ever needs it
ac_id_09 | ID code of the assembly segment assigned by the Election Commission
booth_id_09 | ID code of the polling booth assigned by the Election Commission (together with ac_id_09, this should suffice for matching with other tables)
electors_09 | Number of registered electors
turnout_09 | Number of actual voters
turnout_percent_09 | turnout_09 divided by electors_09
male_votes_09 | Number of male voters
female_votes_09 | Number of female voters
female_votes_percent_09 | female_votes_09 divided by turnout_09
votes_*_09 | Number of votes polled by party *
votes_*_percent_09 | votes_*_09 divided by turnout_09

## Raw data

Originally, this data was crawled using download.pl on April 26, 2013 from http://ceouttarpradesh.nic.in/Form20.aspx.

The data came in excel files, which I manually copy-and-pasted into results.csv since the format differed too much for any automated solution. This file was then cleaned up and an SQL dump prepared through transform.pl for integration into the main database

Also, assembly segment 170 (part of Lucknow) was manually adjusted so as to reflect 2012 polling booth names - the original was in English, which was not very helpful since all other assembly segments were in Hindi...

## License

While the database in its entirety is subject to an [ODC Open Database License](http://opendatacommons.org/licenses/odbl/), as explained in the main [README](https://github.com/raphael-susewind/india-religion-politics/blob/master/README.md) and [LICENSE](https://github.com/raphael-susewind/india-religion-politics/blob/master/LICENSE.md) files, the content of this specific table is factual data, and as such only subject to a simple [ODC Database Contents License](http://opendatacommons.org/licenses/dbcl/).

Code used for crawling and compilation is subject to a [CC-BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) license.
