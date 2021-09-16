# Data on religion and politics in India 

## delhirolls2021

This table contains booth-level estimates of religious demography based on the connotations of electors' names in the electoral rolls of Delhi (revision 2021), using an optimized version of my [name2community](https://github.com/raphael-susewind/name2community) algorithm

## Variables

name | description
--- | ---
id | unique code for each row, in case one ever needs it
ac_id_09 | ID code of the assembly segment assigned by the Election Commission (identical with all other post-delimitation codes, hence the _09)
booth_id_21 | ID code of the polling booth assigned by the Election Commission (together with ac_id_09, this should suffice for matching with other tables)
electors_21 | Number of registered electors
missing_percent_21 | Percentage of electors whose names could not be matched by the algorithm (one crude aggregate measure of reliability)
hindu_percent_21 | Estimated percentage of electors who are Hindu
muslim_percent_21 | Estimated percentage of electors who are Muslim
christian_percent_21 | Estimated percentage of electors who are Christian (be aware that accuracy of the algorithm has only been tested for Hindu and Muslim names, not Christian ones)
sikh_percent_21 | Estimated percentage of electors who are Sikh (be aware that accuracy of the algorithm has only been tested for Hindu and Muslim names, not Sikh ones)
jain_percent_21 | Estimated percentage of electors who are Jain (be aware that accuracy of the algorithm has only been tested for Hindu and Muslim names, not Jain ones)
buddhist_percent_21 | Estimated percentage of electors who are Buddhist (be aware that accuracy of the algorithm has only been tested for Hindu and Muslim names, not Buddhist ones)
age_avg_21 | Average age of all electors
age_stddev_21 | Standard deviation of the age distribution of all electors
female_percent_21 | Percentage of female electors among all electors
age_*_avg_21 | Average age of electors estimated to be * (Hindu / Muslim / Christian / Sikh / Jain / Buddhist)
age_*_stddev_21 | Standard deviation of the age distribution of electors  estimated to be * (Hindu / Muslim / Christian / Sikh / Jain / Buddhist)
female_*_percent_21 | Percentage of female electors among electors estimated to be * (Hindu / Muslim / Christian / Sikh / Jain / Buddhist)
revision_percent_new_21 | Percentage of electors added to this booth's rolls in 2021, against the baseline of 2014
revision_percent_deleted_21 | Percentage of electors deleted from this booth's rolls in 2021, against the baseline of 2014
revision_percent_modified_21 | Percentage of electors modified in this booth's rolls in 2021, against the baseline of 2014

## Raw data

Originally, the electoral rolls were crawled in spring 2021 from http://ceodelhi.gov.in/engdata using run-in-rosalind/downloadpdf.pl; the "last updated on" entry on the rolls' cover sheet reads "15-01-2021".

Raw data itself (electoral roll PDFs as well as the voter-by-voter name classifications derived from them) are not shared here, though, both to save space (it amounts to several GBs of binary dumps) and in light of privacy concerns (electoral rolls are public data, but I doubt that electors like to have their probable religion searchable by EPIC card number). I do archive all relevant original downloads in a restricted access [Zenodo collection](https://zenodo.org/communities/india-religion-politics-raw) though and will make it available to legitimate academic users upon request.

The subsequent processing chain is however preserved in the run-in-rosalind folder for reference. It ran on the [King's College London Rosalind cluster](https://rosalind.kcl.ac.uk) and several hardcoded paths as well as the slurm scheduler commands are unique to this environment. After running createnamedb.pl once and putting all additional software in place, the chain was started using run-delhi.sh, which basically sparked 70 parallel processes (one for each assembly segment), in which roll PDFs were downloaded, OCRed (the original PDFs are image only), relevant data extracted, names of electors matched to likely religion and ultimately booth-wise estimates of religious demography calculated, using ngram technology to further reduce missing_percent_21 (see scripts for details). 

Beware that booth IDs did change between 2014 and 2021. To help compress the delhiid table later on (and calculate revision_percent_*_21 variables), I compared the voter names and relative names in the 2014 rolls to those of the 2021 rolls - discarding multiple matches - and if names from a particular 2021 booth highly overlap with names from a particular 2014 booth assumed that these booths are equivalents (actual integration across years is done by the scripts in the delhiid table itself through delhirolls2021-b.sql).


The final task of pulling everything together for this dataset is delivered by combine.pl, which results in one large booths.sqlite file, which is shared here as .tgz archive (even this is quite large). The SQL code to put this into the main database and create the subsequent CSV dumps was done using transform.pl (this also updates the separate [delhiid](https://github.com/raphael-susewind/india-religion-politics/tree/master/delhiid) table on the fly).

## License

While the database in its entirety is subject to an [ODC Open Database License](http://opendatacommons.org/licenses/odbl/), as explained in the main [README](https://github.com/raphael-susewind/india-religion-politics/blob/master/README.md) and [LICENSE](https://github.com/raphael-susewind/india-religion-politics/blob/master/LICENSE.md) files, the content of this specific table as well as code used for crawling and compilation is subject to a [CC-BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) license: you can use it for non-commercial purposes as long as you attribute and share any additions or modifications on equal terms. 
