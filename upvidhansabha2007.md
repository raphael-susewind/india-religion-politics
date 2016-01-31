# Data on religion and politics in India 

## Booth-level results for 2007 Vidhan Sabha election in Uttar Pradesh

This table contains booth-level (form 20) results for the 2007 Vidhan
Sabha election in Uttar Pradesh.

## Variables

name | description
--- | ---
id | unique auto-increment code for each row, in case one ever needs it
ac_id_07 | ID code of the assembly segment assigned by the Election Commission
ac_name_07 | Name of the assembly segment
ac_reserved_07 | Reservation status of the assembly segment
booth_id_07 | ID code of the polling booth assigned by the Election Commission
station_name_07 | Name of the polling station (cleaned up to be the same across all booths within this station - note that 'polling station' is a concept not used in raw data but introduced by me)
station_id_07 | ID code of the polling station, unique across this table
electors_07 | Number of registered electors
turnout_07 | Number of actual voters
turnout_percent_07 | turnout_07 divided by electors_07
male_votes_07 | Number of male voters
female_votes_07 | Number of female voters
female_votes_percent_07 | female_votes_07 divided by turnout_07
votes_*_07 | Number of votes polled by party *
votes_*_percent_07 | votes_*_07 divided by turnout_07

## Raw data

Originally, this data was crawled using download.pl on October 13,
2012 from http://ceouttarpradesh.nic.in/Form20.aspx.

The data came in excel files, which I manually copy-and-pasted into
results.csv since the format differed too much for any automated
solution. This file was then cleaned up and an SQL dump prepared
through transform.pl for integration into the main database
