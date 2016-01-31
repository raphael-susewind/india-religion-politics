# Data on religion and politics in India 

## upid

This table contains the ID matching and integration table for Uttar Pradesh. Each row is the equivalent of a booth. 

Fully integrated entries would have a booth_id_07, booth_id_09, booth_id_12 etc for this booth - this means I am convinced anything with these ID codes relates to the same actual entity.  But it might also be that an entry has only one or two associated IDs, because I could not safely say how it integrates over time (or because it disappeared / was first instituted at some point). Last but not least, it can also be that an entry with, say, a booth_id_07 has no corresponding booth_id_09, but a station_id_09, or at least an ac_id_09 - in these cases, I am confident that it falls into these wider entities, but cannot say for sure what the new micro equivalent is. All this will basically mean that you will be facing missing values when integrating across various years and related ID codes - its a complicated issue to get your head around, but that's how it is...

## Variables

name | description
--- | ---
id | unique code for each row, in case one ever needs it
ac_id_07 | ID code of the assembly segment that booth falls in, as assigned by the Election Commission in 2007 (pre-delimitation)
ac_name_07 | Name of that assembly segment, as assigned by the Election Commission in 2007 (pre-delimitation)
ac_reserved_07 | Reservation status of that assembly segment, as assigned by the Election Commission in 2007 (pre-delimitation)
booth_id_07 | ID code of the polling booth, as assigned by the Election Commission in 2007 (pre-delimitation)
station_id_07 | ID code of the polling station, i.e. the physical unit housing this polling booth (note that this is a concept not used by the Election Commission, but introduced by me - basically all polling booths with subsequent ID codes and roughly similar names are considered to fall within one station)
station_name_07 | Name of the polling station, i.e. the physical unit housing this polling booth (cleaned up to be the same across all booths within this station)

## Processing

This table is generated using calculate.pl on an otherwise complete dataset SQLite file - the output of this script is then used to alter the original (and not very useful, because not integrated) upid table in that very dataset. In other words: whenever any changes or additions happen to the dataset that concerns ID matching and integration, this script has to be run afterwards, and its output upid.sql incorporated into the table. If you are just downloading the whole dataset, though, this comes with the current version of upid.sql, which is automatically run at the right place by combined.sql. So you should be fine...
