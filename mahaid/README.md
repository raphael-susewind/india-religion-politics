# Data on religion and politics in India 

## mahaid

This table contains the ID matching and integration table for Maharashtra. Each row is the equivalent of a booth. Since the databse only contains data from one year for Maharashtra so far, this is rather straightforward - no actual cross-year matching is necessary.

## Variables

name | description
--- | ---
pc_id_09 | ID code of the parliamentary constituency that booth falls in, as assigned by the Election Commission in 2009 (post-delimitation) - this ID code stays the same for subsequent elections, even though the assembly segments' names might vary
pc_name_09 | Name of that parliamentary constituency, as assigned by the Election Commission in 2009
pc_reserved_09 | Reservation status of that parliamentary constituency, as assigned by the Election Commission in 2009
ac_id_09 | ID code of the assembly segment that booth falls in, as assigned by the Election Commission in 2009 (post-delimitation) - this ID code stays the same for subsequent elections, even though the assembly segments' names might vary
ac_name_14 | Name of that assembly segment, as assigned by the Election Commission in 2014
ac_reserved_14 | Reservation status of that assembly segment, as assigned by the Election Commission in 2014
booth_id_14 | ID code of the polling booth, as assigned by the Election Commission in 2014
station_id_14 | ID code of the polling station, i.e. the physical unit housing this polling booth (note that this is a concept not used by the Election Commission, but introduced by me - basically all polling booths with subsequent ID codes and roughly similar names are considered to fall within one station)
booth_name_14 | Name of the polling booth as listed on the cover sheet of the electoral rolls of 2014
address_14 | Address of the polling booth as listed on the cover sheet of the electoral rolls of 2014
district_14 | District into which this booth falls as listed on the cover sheet of the electoral rolls of 2014
taluk_14 | Taluk into which this booth falls as listed on the cover sheet of the electoral rolls of 2014
thana_14 | Police that jurisdiction into which this booth falls as listed on the cover sheet of the electoral rolls of 2014
village_14 | Village into which this booth falls as listed on the cover sheet of the electoral rolls of 2014
parts_14 | 'Parts' (usually streets) covered by this booth as listed on the cover sheet of the electoral rolls of 2014
pincode_14 | Pincode of this booth as listed on the cover sheet of the electoral rolls of 2014


## Processing

The original entries for this table stem mostly from the various processing scripts of other tables. They are then compressed using compress.pl on an otherwise complete dataset SQLite file (this is the reason why combined.sql is split into combined-a.sql and combined-b.sql - so that compress.pl can be run in between if necessary). In other words: whenever any changes or additions happen to the dataset that concerns ID matching and integration, this script has to be re-run, and its output mahaid.sql incorporated into the table. If you are just downloading the whole dataset, though, this comes with the current version of mahaid.sql, which is automatically run at the right place by subsequently running combined-a.sql and combined-b.sql. So you should be fine...

Two things were added directly in here, though:

* actopc.pl was used to map assembly segments to parliamentary constituencies, derived from http://eci.nic.in/eci_main/archiveofge2009/Stats/VOLIII/VolIII_DetailsOfAssemblySegmentsOfPC.pdf (original download on May 14, 2014) - this gave us pc_id_09, pc_name_09 and pc_reserved_09
* compress.pl determined and parsed in the station_id_14 variable

## License

While the database in its entirety is subject to an [ODC Open Database License](http://opendatacommons.org/licenses/odbl/), as explained in the main [README](https://github.com/raphael-susewind/india-religion-politics/blob/master/README.md) and [LICENSE](https://github.com/raphael-susewind/india-religion-politics/blob/master/LICENSE.md) files, the content of this specific table is factual data, and as such only subject to a simple [ODC Database Contents License](http://opendatacommons.org/licenses/dbcl/). Code used for crawling and compilation is subject to a [CC-BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) license.

What this means in the case of ID tables such as this one is basically: the names of electoral precincts and the like can be used without restrictions, but if you rely on the cross-year and cross-ID matching that this table is meant to facilitate, you are bound by the ODbL attribution and share alike provisions.
