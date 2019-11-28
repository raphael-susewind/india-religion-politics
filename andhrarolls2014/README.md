# Data on religion and politics in India 

## andhrarolls2014

This table contains booth-level estimates of religious demography based on the connotations of electors' names in the electoral rolls of Andhra Pradesh (revision 2014, i.e. the one used for the 2014 Lok Sabha elections), using an optimized version of my [name2community](https://github.com/raphael-susewind/name2community) algorithm

## Variables

name | description
--- | ---
id | unique code for each row, in case one ever needs it
ac_id_09 | ID code of the assembly segment assigned by the Election Commission (identical with all other post-delimitation codes, hence the _09)
booth_id_14 | ID code of the polling booth assigned by the Election Commission (together with ac_id_09, this should suffice for matching with other tables)
electors_14 | Number of registered electors
missing_percent_14 | Percentage of electors whose names could not be matched by the algorithm (one crude aggregate measure of reliability)
hindu_percent_14 | Estimated percentage of electors who are Hindu
muslim_percent_14 | Estimated percentage of electors who are Muslim
christian_percent_14 | Estimated percentage of electors who are Christian (be aware that accuracy of the algorithm has only been tested for Hindu and Muslim names, not Christian ones)
sikh_percent_14 | Estimated percentage of electors who are Sikh (be aware that accuracy of the algorithm has only been tested for Hindu and Muslim names, not Sikh ones)
jain_percent_14 | Estimated percentage of electors who are Jain (be aware that accuracy of the algorithm has only been tested for Hindu and Muslim names, not Jain ones)
buddhist_percent_14 | Estimated percentage of electors who are Buddhist (be aware that accuracy of the algorithm has only been tested for Hindu and Muslim names, not Buddhist ones)
age_avg_14 | Average age of all electors
age_stddev_14 | Standard deviation of the age distribution of all electors
female_percent_14 | Percentage of female electors among all electors
age_*_avg_14 | Average age of electors estimated to be * (Hindu / Muslim / Christian / Sikh / Jain / Buddhist)
age_*_stddev_14 | Standard deviation of the age distribution of electors  estimated to be * (Hindu / Muslim / Christian / Sikh / Jain / Buddhist)
female_*_percent_14 | Percentage of female electors among electors estimated to be * (Hindu / Muslim / Christian / Sikh / Jain / Buddhist)

## Raw data

Originally, the electoral rolls were crawled in July 2014 from http://ceoaperms.ap.gov.in/Electoral_Rolls/PDFGeneration.aspx using run-in-osc/downloadpdf.pl; the "last updated on" entry on the rolls' cover sheet reads "1/1/2014".

Raw data itself (electoral roll PDFs as well as the voter-by-voter name classifications derived from them) are not shared here, though, both to save space (it amounts to several GBs of binary dumps) and in light of privacy concerns (electoral rolls are public data, but I doubt that electors like to have their probable religion searchable by EPIC card number). I do archive all relevant original downloads in a restricted access [Zenodo collection](https://zenodo.org/communities/india-religion-politics-raw) though and will make it available to legitimate academic users upon request.

The subsequent processing chain is however preserved in the run-in-arc folder for reference. It ran on the [Oxford Advanced Research Computing cluster](https://www.arc.ox.ac.uk) and several hardcoded binary paths as well as the Torque scheduler commands are unique to this environment. After running createnamedb.pl once and putting all additional software in place, the chain was started using run.sh, which basically sparked 294 parallel processes (one for each assembly segment), in which roll PDFs were downloaded, relevant data extracted, names of electors matched to likely religion and ultimately booth-wise estimates of religious demography calculated, using ngram technology to further reduce missing_percent_14 (see scripts for details). 

The final task of pulling everything together for this dataset is delivered by combine.pl, which results in one large booths.sqlite file, which is shared here as .tgz archive (even this is quite large). The SQL code to put this into the main database and create the subsequent CSV dumps was done using transform.pl (this also creates the separate [andhraid](https://github.com/raphael-susewind/india-religion-politics/tree/master/andhraid) table on the fly).

## License

While the database in its entirety is subject to an [ODC Open Database License](http://opendatacommons.org/licenses/odbl/), as explained in the main [README](https://github.com/raphael-susewind/india-religion-politics/blob/master/README.md) and [LICENSE](https://github.com/raphael-susewind/india-religion-politics/blob/master/LICENSE.md) files, the content of this specific table as well as code used for crawling and compilation is subject to a [CC-BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) license: you can use it for non-commercial purposes as long as you attribute and share any additions or modifications on equal terms. 
