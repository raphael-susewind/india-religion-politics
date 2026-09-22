# Known issues (September 2026)

This file documents the problems found in a systematic audit of this repository in September 2026, carried out with the help of Claude Code, an AI coding assistant. The database was rebuilt from scratch following the README, and every table, script and document was checked; each finding was then independently re-checked. Unless an issue is marked **fixed in 1.1**, it has not been corrected, and because the repository is retired it will not be. Figures describe the repository as it stood before version 1.1 (commit f2a5fd3, October 2022) unless stated otherwise.

Find the tables and variables you used below. "Booth" means a polling station (part) as identified in the table; "AC" means an assembly constituency.

## Fixed in version 1.1

- **Personal data.** Two files in wbrolls2014 listed 1,000 sampled electors each by name and relative's name, with inferred religion. They were removed and purged from the repository's history (see wbrolls2014/README.md).
- **Small cells.** Statistics resting on fewer than 10 electors were suppressed in all 22 tables of religious demography (see each table's README). About 1.2 million of 1.5 million booth rows lost at least one value.
- **Build.** The build file loaded two files for a table uprolls2021 that never existed, instead of the Haryana 2021 files, and never loaded West Bengal 2021. As a result the build ended with about 1,500 error messages, deleted the harid and wbid tables, and emptied harid.csv and wbid.csv in the user's copy. The build now loads harrolls2021 and wbrolls2021, stops at the first error, and no longer writes into the tracked CSV files.
- **examples/epa2017.sql** failed on a missing comma, repeated in all 13 queries.

## Build and files

- Running the build twice into the same database file duplicates rows in two tables. Start from a new file.
- **delhiid**: a column-order error collapses the 1,390 booths that exist only in the 2021 Delhi roll into 70 garbled rows. The published delhiid.csv has this error.
- The built database has no indexes on the join columns, so large joins are slow.
- Ten tables have no CSV dump. Floating-point values in regenerated CSVs can differ in the last digit, depending on the SQLite version.
- About 1 GB of raw inputs (Form 20 XML files, per-constituency CSVs, PDFs) is committed, although the README says raw data is not included.
- About half the table READMEs list columns that do not exist (female_* where the columns are women_*) or omit columns that do (the parsi_* columns). Trust `PRAGMA table_info`, not the README.

## Religious demography from electoral rolls (all *rolls* tables)

- **What the shares mean.** A community's share is a percentage of the electors whose names could be classified, not of all electors; missing_percent gives the share that could not be classified. Values are truncated, not rounded, to two decimals.
- **Andhra Pradesh, Delhi 2014 and Goa.** An SQL error set missing_percent_14 to 0, so the shares in andhrarolls2014, delhirolls2014 and goarolls2014 are percentages of *all* electors and do not add up to 100 (in Andhra, 57% of electors were unclassified). For shares of classified electors, divide each share by the sum of the seven shares and multiply by 100.
- **Small communities** (Christian, Sikh, Jain, Buddhist, Parsi) are badly misestimated almost everywhere. In UP they come out at 3 to 36 times their census share (the mean estimated Christian share across UP booths is about 5.5%, against 0.18% in the 2011 census). Elsewhere they are off by up to about 125 times, sometimes over- and sometimes under-estimated. Do not use these shares.
- **Muslim / non-Muslim.** Statewide, the estimates are close to the census in Uttar Pradesh, Delhi, Gujarat, Haryana, Kerala and Maharashtra. They are not in Rajasthan, Madhya Pradesh and Odisha, where the estimated Muslim share is roughly 2 to 5 times the census share, nor in West Bengal (see the accuracy test in wbrolls2014/README.md). Statewide agreement does not show that booth-level values are right.
- **Age and sex are unreliable.** In UP 2014-2017, electors whose sex could not be read were counted as women: the electorate-weighted share of women rises to 67% in 2017, with 15,190 booths at exactly 100%. In UP 2017 the age was often read from the wrong number on the roll: 24,267 booths have an average age above 100. Outside UP, the age columns are unusable in the Madhya Pradesh, Maharashtra, Odisha, Rajasthan, Karnataka and Kerala tables, and the women columns in Madhya Pradesh, Maharashtra, Rajasthan, Kerala, Delhi 2014 and West Bengal 2014 and 2021. Where age or sex could not be extracted, some tables report 0 instead of leaving the value empty.
- **The revision variables** (revision_percent_new, _deleted, _modified) should not be used. "modified" is never a percentage (raw counts in 2012-2013, constantly 0 from 2014); "new" exceeds 100% in about 36,000 UP booth rows and holds raw counts in 2017; in the 2021 tables "new" is always 0 and "modified" exceeds 100%.
- **Not comparable across years.** The extraction and classification methods changed from year to year (from 2014 names came from OCR of scanned rolls, and newly added electors were classified differently from continuing ones), so year-to-year changes mostly reflect processing, not demography. The 2014 and 2021 estimates for Delhi, Haryana and West Bengal are not comparable either: the West Bengal Muslim share halves in the same booths.
- **Empty booths.** Booths whose rolls could not be processed appear with no or zero electors but 0.0 in every share (about 10,000 rows across all tables). Treat them as missing.
- **Duplicates.** Whole constituencies appear twice in kerrolls2014, maharolls2014 and orrolls2014, and in their id tables.
- **Missing booths.** The download scripts stopped at part 499. Booths numbered 500 and above are therefore missing in UP ACs 55 (all years), 219 (2014-2017) and 312 (2014-2016), and in Maharashtra AC 203. A cap at part 299 cuts four ACs in Delhi 2021.

## UP rolls (uprolls2011 to uprolls2017)

- **Coverage.** uprolls2014 holds only about 77.5% of the electorate in the 2014 Form 20 (less than 60% in 92 of 403 ACs), and uprolls2015 and 2016 inherit most of the gap. Coverage is good in 2011-2013 and 2017.
- ACs 180 and 333 are missing from uprolls2015 and 2016. ACs 197, 222 and 392 are mostly missing from uprolls2014, which also has 1,174 empty rows without an AC and 611 rows carrying 2013 values under 2014 booth ids.
- In 2014-2016, 12 to 17 ACs show a Christian share of 31-47%. This is an artefact.
- uprolls2015 and 2016 use the columns booth_id_15 and booth_id_16, which are the 2014 booth numbers under another name; join them to other tables on booth_id_14.
- What holds up: the statewide electorate-weighted Muslim share (18.6-19.3% across 2012-2017, against 19.3% in the 2011 census; 17.6% in 2011).

## Rolls of other states

- **The 2021 tables** (delhirolls2021, harrolls2021, wbrolls2021) cover only part of the 2021 electorate, between about a third and three quarters. They also contain rows copied from 2014 under booth_id_21 = 'unclear' (1,164 in Delhi, 308 in Haryana, 2,466 in West Bengal).
- **Undocumented gaps.** About 32 Andhra ACs are severely truncated or empty (among them 263-294); wbrolls2014 lacks all Kolkata ACs; orrolls2014 also lacks some ACs.

## Election results (Form 20 tables)

- **uploksabha2009:** party columns are shifted, and 191 of 288 party vote columns hold another party's votes. Do not use party results from this table.
- **upvidhansabha2017** (marked DRAFT since 2017): values from earlier ACs leak into later ones, and header text was misread as NOTA, turnout, electors or new party columns. About a third of booth rows fail basic vote accounting. ACs 79, 98, 99, 192, 221 and 317 are missing, and a few more are nearly empty. There are two NOTA columns.
- **upvidhansabha2007:** covers 319 of 403 ACs. Votes in ACs 287-290, and electors and turnout in AC 310, are 100 times too large (decimal commas were dropped).
- **uploksabha2014:** female_votes_14 adds female electors to female voters. turnout_percent_14 and female_votes_percent_14 were computed by integer division and are almost always 0. The raw files are incomplete for 11 ACs, which changes the winner in Kannauj.
- **2007, 2009 and 2012:** the male and female vote columns are empty in 92-99% of rows. Votes were lost where party labels were blank or duplicated: 13 ACs of 2012 have almost no party votes. Coverage is 370 of 403 ACs in 2009 and 396 in 2012.
- **gujloksabha2014:** electors_14 holds the total votes polled, not the electorate. The percentage columns were computed by integer division, and turnout excludes NOTA.
- **All tables:** percentages are on a 0-100 scale in some tables and 0-1 in others. Postal-ballot and total rows are mixed in with booths. Party codes are inconsistent between tables.
- What holds up: party shares in upvidhansabha2012 match the official results; uploksabha2014 matches its raw files, and 79 of 80 constituency winners.

## GIS tables

- **The 2021 coordinates are largely unusable.** In delhigis, latitude and longitude are swapped in 97% of 2021 rows, and 40% sit on one filler point. Ten states store 2021 coordinates as unparsed text in numeric columns. Only about 8% of UP 2021 booths have a usable coordinate. andhragis 2021 uses post-2014 Andhra AC numbers in the ac_id_09 column. The 2021 scrape stopped at booth 500 per AC and is incomplete in several states (for example, 61 of 175 ACs in Andhra and 69 of 288 in Maharashtra).
- **Earlier vintages:** about 1,000 UP points fall outside the state. Some booths were geocoded to a centroid (whole ACs on one point; 5-20% of booths share a coordinate). Duplicate (AC, booth) keys multiply rows in joins (upgis 2012, rajgis, kargis). The 2014 and 2017 UP vintages disagree on location in some ACs. kargis 2014 lacks 19 ACs. The MODIS urban flag captures only large cities.
- What holds up: the 2014 coordinates are largely complete and plausible.

## ID tables

- **upid**: station_id_14 is meaningless for about 59% of 2014 booths, because station names were discarded during parsing. This affects the station-level examples (epw2014, samaj2015).
- Cross-year links are strictly one-to-one, so split and new booths stay unlinked. The documented match rates reproduce (about 4% for 2007-2009, 56% for 2009-2012, 98% for 2012-2014); rates from 2014 onwards are not documented.
- goaid has no parliamentary-constituency mapping for 39 of 40 ACs. TROUBLESHOOTING.md refers to merge_XY quality columns that no id table contains. Outside UP the id tables are copies of the 2014 rolls table's keys, not crosswalks between years. Booth names mix Kruti Dev, Latin and Unicode Devanagari, which limits matching.

## Candidate tables

- The religious classification is experimental and should not be relied upon (see the caveat in each README). Measured problems: in 2017, 16 candidates in SC-reserved seats carry labels that are legally impossible there; three BJP candidates are labelled Muslim and one Parsi, in an election in which the party fielded no Muslim candidate; Muslim candidates are under-counted by 15-20%; in Gujarat 2014 two thirds of labels are Unknown.
- The tables keep only one candidate per party per constituency, so most independents are missing. Party codes do not join to the results tables. Parse errors left empty or duplicated rows in 2009 and 2012.

## Examples

- The inputs for several EPA 2017 cities are affected by the issues above: Jaipur, Bhopal and Cuttack by inflated Muslim shares, Hyderabad by the Andhra denominator error. epw2014 and samaj2015 rely on upid's station ids. The VRT files are malformed XML. See also examples/README.md.

## Licences

- The README describes the whole dataset as ODbL-licensed and asks for it to be cited as such. The licence files in the folders differ: the 22 tables of religious demography carry CC BY-NC-SA 4.0, the other tables the ODC Database Contents License. The README states CC BY-NC-SA 4.0 for code, but soundex.py and charmap.py are third-party code under GPL-3.0, and the candidate scripts carry AGPL-3.0 notices. This file records the inconsistency; it does not change any licence.
