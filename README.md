# Data on religion and politics in India

**This repository is retired and no longer maintained (September 2026). Please read this before using any of it.**

In September 2026 I audited this repository systematically, with the help of Claude Code, an AI coding assistant. The audit found a wide range of problems, some of them serious. The documented build did not produce the documented database. Several estimates of religious demography are wrong, or not comparable across years and states. Age and sex figures are corrupt in many tables. Several election-results tables contain parsing errors. All of this is documented, table by table, in [KNOWN-ISSUES.md](KNOWN-ISSUES.md). Most of it has not been corrected, and it will not be: I am retiring the repository.

My own published analyses drew on separately archived replication data or were checked at the time; the example scripts in examples/ reproduce them only approximately and inherit the issues documented here. Others who used this data may have been affected, and should check KNOWN-ISSUES.md against the tables and variables they used.

I still receive regular requests for this data, and I welcome them. But it needs to be seen as a historical record of work done between 2013 and 2022, with the flaws documented here - not as a maintained dataset.

Version 1.1 (22 September 2026) makes these changes and no others:

- personal data that should not have been public (a sample of electors' names in wbrolls2014) was removed and purged from the history of the repository;
- statistics resting on fewer than 10 electors were suppressed in all tables of religious demography (see each table's README);
- the candidate tables now carry a clear caveat that their religious classification is experimental and should not be relied upon;
- the build no longer deletes tables or overwrites files in your copy, and loads the Haryana and West Bengal 2021 tables it used to skip;
- a syntax error in examples/epa2017.sql was fixed;
- the known issues were documented, and the roadmap and invitations to contribute were removed.

This repository provides highly localized statistics on religion and politics in India under an open license. It covers Uttar Pradesh in most detail (2007-2017), and other states for the 2014 general election and, for Delhi, Haryana and West Bengal, 2021. A (potentially incomplete) list of academic usecases for this data is on [Google Scholar](https://scholar.google.com/scholar?oi=bibs&hl=de&cites=11938760322875868825); there is also a separate folder with [examples](https://github.com/raphael-susewind/india-religion-politics/tree/master/examples) to replicate. 

When this work began, transparency initiatives by the Election Commission of India in general and the Chief Electoral Officer of UP in particular allowed researchers to shift the central unit of quantitative political analyses from the constituency level to that of polling booths, stations, and villages. Often, this data is not very user-friendly, though (think garbled, scanned PDFs). The purpose of this repository is to curate this data in a more accessible format and to share the scraping and cleanup code for reference. This official data is then supplemented with estimates of religious demography based on the religious connotations of electors' names in the voter lists (see below).
 
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
[delhirolls2021](https://github.com/raphael-susewind/india-religion-politics/tree/master/delhirolls2021) | Booth-level estimates of religious demography for 2021 across Delhi
[goaid](https://github.com/raphael-susewind/india-religion-politics/tree/master/goaid) | ID matching and integration table for Goa (see below)
[goagis](https://github.com/raphael-susewind/india-religion-politics/tree/master/goagis) | GIS coordinates and other spatial characteristics of polling booths in Goa
[goarolls2014](https://github.com/raphael-susewind/india-religion-politics/tree/master/goarolls2014) | Booth-level estimates of religious demography for 2014 across Goa
[gujid](https://github.com/raphael-susewind/india-religion-politics/tree/master/gujid) | ID matching and integration table for Gujarat (see below)
[gujgis](https://github.com/raphael-susewind/india-religion-politics/tree/master/gujgis) | GIS coordinates and other spatial characteristics of polling booths in Gujarat
[gujloksabha2014](https://github.com/raphael-susewind/india-religion-politics/tree/master/gujloksabha2014) | Booth-level (form 20) results for the 2014 Lok Sabha election from Gujarat
[gujcandidates2014](https://github.com/raphael-susewind/india-religion-politics/tree/master/gujcandidates2014) | Candidates and their likely religion for the 2014 Lok Sabha election from Gujarat (experimental classification - do not rely on it, see caveat)
[gujrolls2014](https://github.com/raphael-susewind/india-religion-politics/tree/master/gujrolls2014) | Booth-level estimates of religious demography for 2014 across Gujarat
[harid](https://github.com/raphael-susewind/india-religion-politics/tree/master/harid) | ID matching and integration table for Haryana (see below)
[hargis](https://github.com/raphael-susewind/india-religion-politics/tree/master/hargis) | GIS coordinates and other spatial characteristics of polling booths in Haryana
[harrolls2014](https://github.com/raphael-susewind/india-religion-politics/tree/master/harrolls2014) | Booth-level estimates of religious demography for 2014 across Haryana
[harrolls2021](https://github.com/raphael-susewind/india-religion-politics/tree/master/harrolls2021) | Booth-level estimates of religious demography for 2021 across Haryana
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
[upcandidates2007](https://github.com/raphael-susewind/india-religion-politics/tree/master/upcandidates2007) | Candidates and their likely religion for the 2007 Vidhan Sabha election in Uttar Pradesh (experimental classification - do not rely on it, see caveat)
[upcandidates2009](https://github.com/raphael-susewind/india-religion-politics/tree/master/upcandidates2009) | Candidates and their likely religion for the 2009 Lok Sabha election from Uttar Pradesh (experimental classification - do not rely on it, see caveat)
[upcandidates2012](https://github.com/raphael-susewind/india-religion-politics/tree/master/upcandidates2012) | Candidates and their likely religion for the 2012 Vidhan Sabha election in Uttar Pradesh (experimental classification - do not rely on it, see caveat)
[upcandidates2014](https://github.com/raphael-susewind/india-religion-politics/tree/master/upcandidates2014) | Candidates and their likely religion for the 2014 Lok Sabha election from Uttar Pradesh (experimental classification - do not rely on it, see caveat)
[upcandidates2017](https://github.com/raphael-susewind/india-religion-politics/tree/master/upcandidates2017) | Candidates and their likely religion for the 2017 Vidhan Sabha election in Uttar Pradesh (experimental classification - do not rely on it, see caveat)
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
[wbrolls2021](https://github.com/raphael-susewind/india-religion-politics/tree/master/wbrolls2021) | Booth-level estimates of religious demography for 2021 across West Bengal


If you wish to **recreate the whole database**, clone this repository in its entirety and, in its top folder, run `sqlite3 combined.sqlite < combined-a.sql` followed by `sqlite3 combined.sqlite < combined-b.sql`. Always start from a new, empty combined.sqlite: running the build twice into the same file duplicates rows. The build takes about 20 minutes and produces a database of about 1.4 GB. It stops at the first error rather than continuing with an incomplete database. The CSV dumps in each folder are not rewritten by the build; if you want fresh ones, run `sqlite3 combined.sqlite < export.sql`, which writes them to a separate export/ folder.

This repository no longer accepts corrections or contributions, and pull requests will not be merged. For the record, every table follows the same **folder structure**:

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

Note that the licence files in the individual folders differ from this summary: the tables of religious demography (the *rolls* folders) carry a CC-BY-NC-SA 4.0 licence, the other tables the ODC Database Contents License, and some code files carry GPL or AGPL notices (see KNOWN-ISSUES.md).

Last but not least, **raw data** behind this dataset (e.g. original files downloaded from ECI websites over the years) is generally not included here, both to save space (it runs into several TB by now) and for privacy concerns (even though all data was originally put in the public domain by the ECI, some of it might be considered sensitive in aggregate). I do archive all relevant original downloads in a restricted access [Zenodo collection](https://zenodo.org/communities/india-religion-politics-raw) though and will make it available to legitimate academic users upon request.

I provide this dataset without any guarantee. Before using it, please read [KNOWN-ISSUES.md](KNOWN-ISSUES.md) and, for the general problems of this kind of data, [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

Raphael Susewind, mail@raphael-susewind.de, GPG key [10AEE42F](https://keybase.io/raphaelsusewind)
