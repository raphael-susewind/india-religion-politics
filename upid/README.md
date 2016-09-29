# Data on religion and politics in India 

## upid

This table contains the ID matching and integration table for Uttar Pradesh. Each row is the equivalent of a booth. 

Fully integrated entries would have a booth_id_07, booth_id_09, booth_id_12 etc for this booth - this means I am convinced anything with these ID codes relates to the same actual entity.  But it might also be that an entry has only one or two associated IDs, because I could not safely say how it integrates over time (or because it disappeared / was first instituted at some point). Across the state, only 4% of booths from 2007 could be matched to their equivalent in 2009 (particularly challenging because of the major delimitation exercise in between - and yes, that means its basically useless unless you are interested in the few constituencies where it worked), 56% of 2009 booths were matched to 2012, and 98% of 2012 booths were matched to 2014. Last but not least, it can also be that an entry with, say, a booth_id_07 has no corresponding booth_id_09, but a station_id_09, or at least an ac_id_09 - in these cases, I am confident that it falls into these wider entities, but cannot say for sure what the new micro equivalent is. All this will basically mean that you will be facing missing values when integrating across various  years and related ID codes - its a complicated issue to get your head around, but that's how it is...

## Variables

name | description
--- | ---
ac_id_07 | ID code of the assembly segment that booth falls in, as assigned by the Election Commission in 2007 (pre-delimitation)
ac_name_07 | Name of that assembly segment, as assigned by the Election Commission in 2007 (pre-delimitation)
ac_reserved_07 | Reservation status of that assembly segment, as assigned by the Election Commission in 2007 (pre-delimitation)
booth_id_07 | ID code of the polling booth, as assigned by the Election Commission in 2007 (pre-delimitation)
station_id_07 | ID code of the polling station, i.e. the physical unit housing this polling booth (note that this is a concept not used by the Election Commission, but introduced by me - basically all polling booths with subsequent ID codes and roughly similar names are considered to fall within one station)
station_name_07 | Name of the polling station, i.e. the physical unit housing this polling booth (cleaned up to be the same across all booths within this station)
pc_id_09 | ID code of the parliamentary constituency that booth falls in, as assigned by the Election Commission in 2009 (post-delimitation) - this ID code stays the same for subsequent elections, even though the assembly segments' names might vary
pc_name_09 | Name of that parliamentary constituency, as assigned by the Election Commission in 2009
ac_id_09 | ID code of the assembly segment that booth falls in, as assigned by the Election Commission in 2009 (post-delimitation) - this ID code stays the same for subsequent elections, even though the assembly segments' names might vary
ac_name_09 | Name of that assembly segment, as assigned by the Election Commission in 2009
ac_reserved_09 | Reservation status of that assembly segment, as assigned by the Election Commission in 2009
booth_id_09 | ID code of the polling booth, as assigned by the Election Commission in 2009
station_id_09 | ID code of the polling station, i.e. the physical unit housing this polling booth (note that this is a concept not used by the Election Commission, but introduced by me - basically all polling booths with subsequent ID codes and roughly similar names are considered to fall within one station)
station_name_09 | Name of the polling station, i.e. the physical unit housing this polling booth (cleaned up to be the same across all booths within this station)
ac_name_12 | Name of that assembly segment, as assigned by the Election Commission in 2012
ac_reserved_12 | Reservation status of that assembly segment, as assigned by the Election Commission in 2012
booth_id_12 | ID code of the polling booth, as assigned by the Election Commission in 2012
station_id_12 | ID code of the polling station, i.e. the physical unit housing this polling booth (note that this is a concept not used by the Election Commission, but introduced by me - basically all polling booths with subsequent ID codes and roughly similar names are considered to fall within one station)
station_name_12 | Name of the polling station, i.e. the physical unit housing this polling booth (cleaned up to be the same across all booths within this station
ac_name_14 | Name of that assembly segment, as assigned by the Election Commission in 2014
ac_reserved_14 | Reservation status of that assembly segment, as assigned by the Election Commission in 2014
booth_id_14 | ID code of the polling booth, as assigned by the Election Commission in 2014
station_id_14 | ID code of the polling station, i.e. the physical unit housing this polling booth (note that this is a concept not used by the Election Commission, but introduced by me - basically all polling booths with subsequent ID codes and roughly similar names are considered to fall within one station)
station_name_14 | Name of the polling station, i.e. the physical unit housing this polling booth (cleaned up to be the same across all booths within this station)
booth_parts_14 | List of the constituent 'parts' (in ECI parlance) for this polling booth in 2014 - usually the streets, mohallas or villages served
booth_name_14 | Name of the polling booth as listed in the psname2partname database (this might be different from station_name_14)
district_11 | District into which this booth falls as identically listed on the cover sheet of the electoral rolls of 2011, 2012 and 2013
tehsil_11 | Tehsil into which this booth falls as identically listed on the cover sheet of the electoral rolls of 2011, 2012 and 2013
village_11 | Village into which this booth falls as identically listed on the cover sheet of the electoral rolls of 2011, 2012 and 2013 (only rural booths)
town_11 | Town into which this booth falls as identically listed on the cover sheet of the electoral rolls of 2011, 2012 and 2013 (only urban booths)
ward_11 | Ward into which this booth falls as identically listed on the cover sheet of the electoral rolls of 2011, 2012 and 2013 (only urban booths)
thana_11 | Police thana jurisdiction into which this booth falls as identically listed on the cover sheet of the electoral rolls of 2011, 2012 and 2013
circlecourt_11 | Court jurisdiction into which this booth falls as identically listed on the cover sheet of the electoral rolls of 2011, 2012 and 2013
station_name_11 |Station name of this booth as identically listed on the cover sheet of the electoral rolls of 2011, 2012 and 2013 (might be the same or not as the various station_name_* variables generated by comparing names across subsequent booth IDs)
station_address_11 | Address of the station into which this booth falls as identically listed on the cover sheet of the electoral rolls of 2011, 2012 and 2013
areas_11 | Areas (aka 'parts') which this booth covers as identically listed on the cover sheet of the electoral rolls of 2011, 2012 and 2013
pincode_11 | Pincode of this booth as identically listed on the cover sheet of the electoral rolls of 2011, 2012 and 2013

## Processing

The original entries for this table stem mostly from the various processing scripts of other tables. They are then compressed using compress.pl on an otherwise complete dataset SQLite file (this is the reason why combined.sql is split into combined-a.sql and combined-b.sql - so that compress.pl can be run in between if necessary). In other words: whenever any changes or additions happen to the dataset that concerns ID matching and integration, this script has to be re-run, and its output upid.sql incorporated into the table. If you are just downloading the whole dataset, though, this comes with the current version of upid.sql, which is automatically run at the right place by subsequently running combined-a.sql and combined-b.sql. So you should be fine...

A few things were added directly in here, though. These are:

* actopc.pl was used to map assembly segments to parliamentary constituencies, derived from http://eci.nic.in/eci_main/archiveofge2009/Stats/VOLIII/VolIII_DetailsOfAssemblySegmentsOfPC.pdf (original download on May 14, 2014) - this gave us pc_id_09, pc_name_09 and pc_reserved_09
* psname2partname.pl was used to map each polling station to its component 'parts', scraped from http://164.100.180.82/blosearch/bloSearching.aspx (a CEO Uttar Pradesh website; original download on April 19, 2014) - this gave us booth_parts_14 and booth_name_14

The integration across years from 2007 to 2012 uses a fairly messy - and barely working - combination of name matching (are station_name_07 and station_name_09 similar enough), relative position of the polling booth in the overall list (similarly named stations that are both at the beginning of an assembly segment's list of booths are more likely to be equivalent than those positioned farther away) and changes in the number of electors (if it changes dramatically, it is less likely to be the equivalent booth). The fuzzy logic is tuned to be conservative (better to integrate less rather than wrongly), but it is still worth checking a sample of matches manually before you use this table to combine data across these years. This warning is particularly important when it comes to the combination of pre-delimitation (2007) and post-delimitation (2009 onwards) data. Also note that integration completely fails if different years use different scripts for station names (which varies constityency by constituency). See main [TROUBLESHOOTING](https://github.com/raphael-susewind/india-religion-politics/blob/master/TROUBLESHOOTING.md) advice for more detail and [upid-a.stats.txt](https://github.com/raphael-susewind/india-religion-politics/blob/master/upid/upid-a.stats.txt) for an overview of matching results.

Fortunately, however, having access to the electoral rolls since 2011 makes it much easier to find out which polling booth in 2011-13 equals which in 2014 (and in future) - to establish this this, I just looked up where the vast majority of voter IDs listed in any given booth in 2011-13 were listed in 2014, and assumed these two booths to be referring to the same physical entity (this integration is actually done by the scripts in the [uprolls2014](https://github.com/raphael-susewind/india-religion-politics/tree/master/uprolls2014) table).  

## License

While the database in its entirety is subject to an [ODC Open Database License](http://opendatacommons.org/licenses/odbl/), as explained in the main [README](https://github.com/raphael-susewind/india-religion-politics/blob/master/README.md) and [LICENSE](https://github.com/raphael-susewind/india-religion-politics/blob/master/LICENSE.md) files, the content of this specific table is factual data, and as such only subject to a simple [ODC Database Contents License](http://opendatacommons.org/licenses/dbcl/). Code used for crawling and compilation is subject to a [CC-BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) license.

What this means in the case of ID tables such as this one is basically: the names of electoral precincts and the like can be used without restrictions, but if you rely on the cross-year and cross-ID matching that this table is meant to facilitate, you are bound by the ODbL attribution and share alike provisions.
