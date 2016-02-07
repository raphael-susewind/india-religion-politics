# Data on religion and politics in India 

## uploksabha2014

This table contains booth-level (form 20) results for the 2014 Lok Sabha election from Uttar Pradesh.

## Variables

name | description
--- | ---
id | unique code for each row, in case one ever needs it
ac_id_09 | ID code of the assembly segment assigned by the Election Commission (identical with all other post-delimitation codes, hence the _09)
booth_id_14 | ID code of the polling booth assigned by the Election Commission (together with ac_id_09, this should suffice for matching with other tables)
electors_14 | Number of registered electors
turnout_14 | Number of valid votes
turnout_percent_14 | turnout_14 divided by electors_14
nota_14 | Number of times the "None of the above" option was chosen
tendered_14 | Number of tendered votes
male_votes_14 | Number of male voters
female_votes_14 | Number of female voters
female_votes_percent_14 | female_votes_14 divided by turnout_14
votes_*_14 | Number of votes polled by party *
votes_*_percent_14 | votes_*_14 divided by turnout_14

## Raw data

Originally, this data was crawled using the code in download.pl on June 17, 2014 from http://164.100.180.4/ceouptemp/districtwiseform20report.aspx (a CEO Uttar Pradesh website).

The tables that matched candidates to political parties were originally prepared by Dilip Damle and shared on the datameet mailing list on May 29, 2014. His email is archived at https://groups.google.com/forum/#!topic/datameet/AzmAb0VhczI. Thank you, Dilip!

Both sources were combined to create the actual table using the transform.pl script.

## License

While the database in its entirety is subject to an [ODC Open Database License](http://opendatacommons.org/licenses/odbl/), as explained in the main [README](https://github.com/raphael-susewind/india-religion-politics/blob/master/README.md) and [LICENSE](https://github.com/raphael-susewind/india-religion-politics/blob/master/LICENSE.md) files, the content of this specific table is factual data, and as such only subject to a simple [ODC Database Contents License](http://opendatacommons.org/licenses/dbcl/). Code used for crawling and compilation is subject to a [CC-BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) license.
