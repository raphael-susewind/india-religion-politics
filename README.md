# Data on religion and politics in India

This repository provides highly localized statistics on religion and politics in India under an open license. I aim to cover Uttar Pradesh as comprehensively as possible, and the rest of India during general elections (see [roadmap](https://github.com/raphael-susewind/india-religion-politics/tree/master/ROADMAP.md)) and/or if other people contribute. A (potentially incomplete) list of academic usecases for this data is on [Google Scholar](https://scholar.google.com/scholar?oi=bibs&hl=de&cites=11938760322875868825); there is also a separate folder with [examples](https://github.com/raphael-susewind/india-religion-politics/tree/master/examples) to replicate. 

Fortunately, recent transparency initiatives by the Election Commission of India in general and the Chief Electoral Officer of UP in particular now allow researchers to shift the central unit of quantitative political analyses from the constituency level to that of polling booths, stations, and villages (earlier, such data had to be interpolated or estimated). Often, this data is not very user-friendly, though (think garbled, scanned PDFs). The purpose of this repository is to curate this data in a more accessible format and to share the scraping and cleanup code for reference. This official data is then supplemented with estimates of religious demography based on the religious connotations of electors' names in the voter lists (see below).
 
From 2013 to 2015, the whole dataset was located on my [personal website](https://www.raphael-susewind.de), and the [blog there](https://www.raphael-susewind.de/blog/category/quantitativemethods) continues to provide bits and pieces of advice on how to use it, as do my various [publications](https://writing.raphael-susewind.de). This created unnecessary hurdles for collaboration, though, and created its unique challenges in terms of long-term availability. After pondering various options, I decided to move to GitHub entirely. Technically, the final dataset comes as a **SQLite database** with a number of relational tables:


table | description
--- | ---
[examples](https://github.com/raphael-susewind/india-religion-politics/tree/master/examples) | Example queries that would replicate published papers based on this data
[andhraid](https://github.com/raphael-susewind/india-religion-politics/tree/master/andhraid) | ID matching and integration table for Andhra Pradesh (see below)
[andhragis](https://github.com/raphael-susewind/india-religion-politics/tree/master/andhragis) | GIS coordinates and other spatial characteristics of polling booths in Andhra Pradesh
[andhrarolls2014](https://github.com/raphael-susewind/india-religion-politics/tree/master/andhrarolls2014) | Booth-level estimates of religious demography for 2014 across Andhra Pradesh
[delhiid](https://github.com/raphael-susewind/india-religion-politics/tree/master/delhiid) | ID matching and integration table for Delhi (see below)
[delhigis](https://github.com/raphael-susewind/india-religion-politics/tree/master/delhigis) | GIS coordinates and other spatial characteristics of polling booths in Delhi
[delhirolls2014](https://github.com/raphael-susewind/india-religion-politics/tree/master/delhirolls2014) | Booth-level estimates of religious demography for 2014 across Delhi
[gujid](https://github.com/raphael-susewind/india-religion-politics/tree/master/gujid) | ID matching and integration table for Gujarat (see below)
[gujgis](https://github.com/raphael-susewind/india-religion-politics/tree/master/gujgis) | GIS coordinates and other spatial characteristics of polling booths in Gujarat
[gujloksabha2014](https://github.com/raphael-susewind/india-religion-politics/tree/master/gujloksabha2014) | Booth-level (form 20) results for the 2014 Lok Sabha election from Gujarat
[gujcandidates2014](https://github.com/raphael-susewind/india-religion-politics/tree/master/gujcandidates2014) | Candidates and their likely religion for the 2014 Lok Sabha election from Gujarat
[gujrolls2014](https://github.com/raphael-susewind/india-religion-politics/tree/master/gujrolls2014) | Booth-level estimates of religious demography for 2014 across Gujarat
[harid](https://github.com/raphael-susewind/india-religion-politics/tree/master/harid) | ID matching and integration table for Haryana (see below)
[hargis](https://github.com/raphael-susewind/india-religion-politics/tree/master/hargis) | GIS coordinates and other spatial characteristics of polling booths in Haryana
[harrolls2014](https://github.com/raphael-susewind/india-religion-politics/tree/master/harrolls2014) | Booth-level estimates of religious demography for 2014 across Haryana
[karid](https://github.com/raphael-susewind/india-religion-politics/tree/master/karid) | ID matching and integration table for Karnataka (see below)
[kargis](https://github.com/raphael-susewind/india-religion-politics/tree/master/kargis) | GIS coordinates and other spatial characteristics of polling booths in Karnataka
[karrolls2014](https://github.com/raphael-susewind/india-religion-politics/tree/master/karrolls2014) | Booth-level estimates of religious demography for 2014 across Karnataka
[kerid](https://github.com/raphael-susewind/india-religion-politics/tree/master/kerid) | ID matching and integration table for Kerala (see below)
[kergis](https://github.com/raphael-susewind/india-religion-politics/tree/master/kergis) | GIS coordinates and other spatial characteristics of polling booths in Kerala
[kerrolls2014](https://github.com/raphael-susewind/india-religion-politics/tree/master/kerrolls2014) | Booth-level estimates of religious demography for 2014 across Kerala
[mpid](https://github.com/raphael-susewind/india-religion-politics/tree/master/mpid) | ID matching and integration table for Madhya Pradesh (see below)
[mpgis](https://github.com/raphael-susewind/india-religion-politics/tree/master/mpgis) | GIS coordinates and other spatial characteristics of polling booths in Madhya Pradesh
[mprolls2014](https://github.com/raphael-susewind/india-religion-politics/tree/master/mprolls2014) | Booth-level estimates of religious demography for 2014 across Madhya Pradesh
[mahaid](https://github.com/raphael-susewind/india-religion-politics/tree/master/mahaid) | ID matching and integration table for Maharashtra (see below)
[mahagis](https://github.com/raphael-susewind/india-religion-politics/tree/master/mahagis) | GIS coordinates and other spatial characteristics of polling booths in Maharashtra
[maharolls2014](https://github.com/raphael-susewind/india-religion-politics/tree/master/maharolls2014) | Booth-level estimates of religious demography for 2014 across Maharashtra
[orid](https://github.com/raphael-susewind/india-religion-politics/tree/master/orid) | ID matching and integration table for Orissa (see below)
[orgis](https://github.com/raphael-susewind/india-religion-politics/tree/master/orgis) | GIS coordinates and other spatial characteristics of polling booths in Orissa
[orrolls2014](https://github.com/raphael-susewind/india-religion-politics/tree/master/orrolls2014) | Booth-level estimates of religious demography for 2014 across Orissa
[rajid](https://github.com/raphael-susewind/india-religion-politics/tree/master/rajid) | ID matching and integration table for Rajasthan (see below)
[rajgis](https://github.com/raphael-susewind/india-religion-politics/tree/master/rajgis) | GIS coordinates and other spatial characteristics of polling booths in Rajasthan
[rajrolls2014](https://github.com/raphael-susewind/india-religion-politics/tree/master/rajrolls2014) | Booth-level estimates of religious demography for 2014 across Rajasthan
[upid](https://github.com/raphael-susewind/india-religion-politics/tree/master/upid) | ID matching and integration table for Uttar Pradesh (see below)
[upgis](https://github.com/raphael-susewind/india-religion-politics/tree/master/upgis) | GIS coordinates and other spatial characteristics of polling booths in Uttar Pradesh
[upvidhansabha2007](https://github.com/raphael-susewind/india-religion-politics/tree/master/upvidhansabha2007) | Booth-level (form 20) results for the 2007 Vidhan Sabha election in Uttar Pradesh
[uploksabha2009](https://github.com/raphael-susewind/india-religion-politics/tree/master/uploksabha2009) | Booth-level (form 20) results for the 2009 Lok Sabha election from Uttar Pradesh
[upvidhansabha2012](https://github.com/raphael-susewind/india-religion-politics/tree/master/upvidhansabha2012) | Booth-level (form 20) results for the 2012 Vidhan Sabha election in Uttar Pradesh
[uploksabha2014](https://github.com/raphael-susewind/india-religion-politics/tree/master/uploksabha2014) | Booth-level (form 20) results for the 2014 Lok Sabha election from Uttar Pradesh
[upvidhansabha2017](https://github.com/raphael-susewind/india-religion-politics/tree/master/upvidhansabha2017) | Booth-level (form 20) results for the 2017 Vidhan Sabha election in Uttar Pradesh
[upcandidates2007](https://github.com/raphael-susewind/india-religion-politics/tree/master/upcandidates2007) | Candidates and their likely religion for the 2007 Vidhan Sabha election in Uttar Pradesh
[upcandidates2009](https://github.com/raphael-susewind/india-religion-politics/tree/master/upcandidates2009) | Candidates and their likely religion for the 2009 Lok Sabha election from Uttar Pradesh
[upcandidates2012](https://github.com/raphael-susewind/india-religion-politics/tree/master/upcandidates2012) | Candidates and their likely religion for the 2012 Vidhan Sabha election in Uttar Pradesh
[upcandidates2014](https://github.com/raphael-susewind/india-religion-politics/tree/master/upcandidates2014) | Candidates and their likely religion for the 2014 Lok Sabha election from Uttar Pradesh
[upcandidates2017](https://github.com/raphael-susewind/india-religion-politics/tree/master/upcandidates2017) | Candidates and their likely religion for the 2017 Vidhan Sabha election in Uttar Pradesh
[uprolls2011](https://github.com/raphael-susewind/india-religion-politics/tree/master/uprolls2011) | Booth-level estimates of religious demography for 2011 across Uttar Pradesh
[uprolls2012](https://github.com/raphael-susewind/india-religion-politics/tree/master/uprolls2012) | Booth-level estimates of religious demography for 2012 across Uttar Pradesh
[uprolls2013](https://github.com/raphael-susewind/india-religion-politics/tree/master/uprolls2013) | Booth-level estimates of religious demography for 2013 across Uttar Pradesh
[uprolls2014](https://github.com/raphael-susewind/india-religion-politics/tree/master/uprolls2014) | Booth-level estimates of religious demography for 2014 across Uttar Pradesh
[uprolls2015](https://github.com/raphael-susewind/india-religion-politics/tree/master/uprolls2015) | Booth-level estimates of religious demography for 2015 across Uttar Pradesh
[uprolls2016](https://github.com/raphael-susewind/india-religion-politics/tree/master/uprolls2016) | Booth-level estimates of religious demography for 2016 across Uttar Pradesh
[uprolls2017](https://github.com/raphael-susewind/india-religion-politics/tree/master/uprolls2017) | Booth-level estimates of religious demography for 2017 across Uttar Pradesh
[wbid](https://github.com/raphael-susewind/india-religion-politics/tree/master/wbid) | ID matching and integration table for West Bengal (see below)
[wbgis](https://github.com/raphael-susewind/india-religion-politics/tree/master/wbgis) | GIS coordinates and other spatial characteristics of polling booths in West Bengal
[wbrolls2014](https://github.com/raphael-susewind/india-religion-politics/tree/master/wbrolls2014) | Booth-level estimates of religious demography for 2014 across West Bengal


If you wish to **recreate the whole database**, the easiest way would be to clone this repository in its entirety, and then run the equivalent of `cat combined-a.sql | sqlite3 combined.sqlite` and `cat combined-b.sql | sqlite3 combined.sqlite` on your system. This will automatically create a new combined.sqlite file by running all table.sql files in the correct order. You can then extract your data from one or multiple tables for further processing using standard SQL commands. 

If you wish to **add or correct stuff** in the dataset, you can either send me an informal email (see below) or, if sufficiently technically minded, create a pull request against this repository. If making corrections or merely adding more variables to an existing table, please update the respective README.md with an explanation, update table.sql with the necessary SQL code, and create a new table.csv dump (code for which should already be included in the table.sql). If adding entirely new tables, please follow this **folder structure** that applies to all tables:

* table - a directory containing the scraping and cleanup code used to generate this table from raw data. Note that the raw data itself can often not be redistributed for legal reasons and may not be available at its earstwhile URL anymore - a chief reason to curate this repository. If you want access to original raw data in order to check the scripts, drop me an email and we can arrange something.
* table/README.md - a description of each variable in this table alongside notes on raw data sources, notes on accuracy, and, if relevant, additional license information.
* table/LICENSE.md - a copy of the data license (which may be different from the database license at large, see below)
* table/table.sql - a set of SQLite commands that you can use to add the table to your master database using combined.sql (see below; this might be split into several files if they get too large).
* table/table.csv - a CSV dump of said table. I personally prefer to work straight from SQLite, but you may not (this might again be split into several files).

One particularly important set of tables are the various "id" ones - they map the **ID codes** across the dataset against each other (there is one id table per state, re-generated after each addition to the dataset). Unfortunately, but necessarily, the Election Commission changes polling booth IDs and names once in a while and we had a delimitation exercise in 2008 with even starker impact on precincts. Consequently, you cannot simply assume that, for instance, booth 143 in constituency 47 of Uttar Pradesh in the uploksabha2014 table is the same entity as booth 143 in constituency 47 of Uttar Pradesh in the upvidhansabha2012 table. Likewise, spatial matching - for instance used to tell which district a given polling station falls into - has its own set of inaccuracies. So if you need to combine tables with a different set of ID codes, you need to look up what matches what in the state's id table (id codes with the same name are directly compatible across tables within the same state)

The estimates of **religious demography** use an algorith which is also on [GitHub](https://github.com/raphael-susewind/name2community/tree/ngram) and described more fully in the following article of mine (upscaling was generously sponsored by the [Oxford Advanced Research Computing unit](http://arc.ox.ac.uk)):

> Susewind, R. (2015). [What's in a name? Probabilistic inference of religious community from South Asian names](http://dx.doi.org/10.1177/1525822X14564275). Field Methods 27(4), 319-332. 
 
Another useful source that complements this data are the **GIS shapefiles** for assembly segments and parliamentary constituencies which are included in the following dataset; the ID codes used therein are compatible to the *loksabha2014 tables (note that the polling booth localities as such are also directly embedded in the *gis tables, so you only need the shapefiles to map higher levels of aggregation):

> Susewind, R. (2014). [GIS shapefiles for India's parliamentary and assembly constituencies including polling booth localities](http://dx.doi.org/10.4119/unibi/2674065). Published under a CC-BY-NC-SA 4.0 license. Available from http://dx.doi.org/10.4119/unibi/2674065.

The dataset in its entirety is **licensed** under an [ODC Open Database license](http://www.opendatacommons.org/licenses/odbl/). This allows you to download, copy, use and redistribute it, as long as you attribute correctly, abstrain from technical methods of copy protection, and most importantely make any additions and modifications publicly available on equal terms (preferably on this very repository). A number of tables in this dataset come with their own legal baggage, which is mentioned and explained further in their respective README.md and LICENSE.md files. Code used for crawling and compilation is subject to a [CC-BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) license. In an academic context, I suggest you attribute using this reference:

> Susewind, R. (2016). Data on religion and politics in India. Published under an ODbL 1.0 license. Available from https://github.com/raphael-susewind/india-religion-politics.

So I invite all to download and use this dataset for more localized quantitative analyses of political, religious and demographic dynamics in India in the spirit of Open Data sharing. Please let me know if you find the dataset useful and alert me to errors and mistakes. I provide this dataset without any guarantee - see [troubleshooting notes](https://github.com/raphael-susewind/india-religion-politics/blob/master/TROUBLESHOOTING.md) for **known general problems** with this data, alongside the various table READMEs.

Raphael Susewind, mail@raphael-susewind.de, GPG key [10AEE42F](https://keybase.io/raphaelsusewind)
