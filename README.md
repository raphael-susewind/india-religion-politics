# Data on religion and politics in India

This repository provides highly localized statistics on religion and politics in India under an open license, focussing largely on North Indian states, and especially on Uttar Pradesh. 

Fortunately, recent transparency initiatives by the Election Commission of India in general and the Chief Electoral Officer of UP in particular now allow researchers to shift the central unit of quantitative political analyses from the constituency level to that of polling booths, stations, and villages (earlier, such data had to be interpolated or estimated). Often, this data is not very user-friendly, though (think garbled, scanned PDFs). The purpose of this repository is to curate this data in a more accessible format and to share the scraping and cleanup code for reference.

Moreover, official data is supplemented with estimates of religious demography based on the religious connotations of electors' names in the voter lists. Upscaling was generously sponsored by the [Oxford Advanced Research Computing unit](http://arc.ox.ac.uk); the algorith itself is on [GitHub](https://github.com/raphael-susewind/name2community/tree/ngram) and described more fully in the following article of mine:

> Susewind, Raphael (2015). [What's in a name? Probabilistic inference of religious community from South Asian names](http://dx.doi.org/10.1177/1525822X14564275). Field Methods 27(4), 319-332. 

Another useful source that complements this data are the GIS shapefiles for polling booths, stations, assembly segments and parliamentary constituencies which I published here:

> Susewind, R. (2014). [GIS shapefiles for India's parliamentary and assembly constituencies including polling booth localities](http://dx.doi.org/10.4119/unibi/2674065). Published under a CC-BY-NC-SA 4.0 license.

From 2013 to 2016, the whole dataset was located on my [personal website](https://www.raphael-susewind.de), and the [blog there](https://www.raphael-susewind.de/blog/category/quantitativemethods) continues to provide bits and pieces of advice on how to use it, as do my various [publications](https://writing.raphael-susewind.de). This created unnecessary hurdles for collaboration, though, and created its unique challenges in terms of long-term availability. After pondering various options, I decided to move to GitHub entirely. Technically, the final dataset comes as a **SQLite database** with a number of relational tables:

table | description
--- | ---
upid | ID matching and integration table for Uttar Pradesh (see below)
upvidhansabha2007 | Booth-level (form 20) results for the 2007 Vidhan Sabha election in Uttar Pradesh
uploksabha2009 | Booth-level (form 20) results for the 2009 Lok Sabha election from Uttar Pradesh
upvidhansabha2012 | Booth-level (form 20) results for the 2012 Vidhan Sabha election in Uttar Pradesh

If you wish to **recreate the whole database**, the easiest way would be to clone this repository in its entirety, and then run the equivalent of `cat combined.sql | sqlite3 combined.sqlite` on your system. This will automatically create a new combined.sqlite file by running all table.sql files in the correct order. You can then extract your data from one or multiple tables for further processing. 

If you wish to **add or correct stuff** in the dataset, you can either send me an informal email (see below) or, if sufficiently technically minded, create a pull request against this repository. If making corrections or merely adding more variables to an existing table, please update the respective README.md with an explanation, update table.sql with the necessary SQL code, and create a new table.csv dump (code for which should already be included in the table.sql). If adding new tables, please follow this structure that applies to all tables:

* table - a directory containing the scraping and cleanup code used to generate this table from raw data. Note that the raw data itself can often not be redistributed for legal reasons and may not be available at its earstwhile URL anymore - a chief reason to curate this repository. If you want access to original raw data in order to check the scripts, drop me an email and we can arrange something.
* table/README.md - a description of each variable in this table alongside notes on raw data sources, notes on accuracy, and, if relevant, additional license information.
* table/LICENSE.md - a copy of the data license (which may be different from the database license at large, see below)
* table/table.sql - a set of SQLite commands that you can use to add the table to your master database using combined.sql (see below; this might be split into several files if they get too large).
* table/table.csv - a CSV dump of said table. I personally prefer to work straight from SQLite, but you may not (this might again be split into several files).

One particularly important set of tables are the various "id" ones - they map the various **ID codes** in use across the dataset against each other (there is one id table per state, re-generated after each addition to the dataset). Unfortunately, but necessarily, the Election Commission changes polling booth IDs and names once in a while and we had a delimitation exercise in 2008 with even starker impact on precincts. Consequently, you cannot simply assume that, for instance, booth 143 in constituency 47 of Uttar Pradesh in the uploksabha2014 table is the same entity as booth 143 in constituency 47 of Uttar Pradesh in the upvidhansabha2012 table. Likewise, spatial matching - for instance used to tell which district and taluqa a given polling station falls into - has its own set of inaccuracies. So if you need to combine tables with a different set of ID codes, you need to look up what matches what in the state's id table (id codes with the same name are directly compatible across tables within the same state). 

The dataset in its entirety is **licensed** under an [ODC Open Database license](http://www.opendatacommons.org/licenses/odbl/1.0/). This allows you to download, copy, use and redistribute it, as long as you attribute correctly, abstrain from technical methods of copy protection, and most importantely make any additions and modifications publicly available on equal terms. A number of tables in this dataset come with their own legal baggage, which is mentioned and explained further in their respective table.md file. In an academic context, I suggest you attribute using this reference:

> Susewind, R. (2016). Data on religion and politics in India. Published under an ODbL 1.0 license. https://data.raphael-susewind.de.

I invite all to download and use this dataset for more localized quantitative analyses of political, religious and demographic dynamics in India in the spirit of Open Data sharing and subject to applicable license conditions - in particular the requirement to share alterations and additions to the dataset with the research community on equivalent terms. Please let me know if you find the dataset useful and alert me to errors and mistakes. I provide this dataset without any guarantee - see [troubleshooting notes](https://github.com/raphael-susewind/india-religion-politics/blob/master/TROUBLESHOOTING.md) for important notes on known **general problems** with this data.

Raphael Susewind, mail@raphael-susewind.de, GPG key 10AEE42F
