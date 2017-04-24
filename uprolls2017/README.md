# Data on religion and politics in India 

## uprolls2017

This table contains booth-level estimates of religious demography based on the connotations of electors' names in the electoral rolls of Uttar Pradesh (revision 2017 - ie the one used for the Vidhan Sabha elections that year), using an optimized version of my [name2community](https://github.com/raphael-susewind/name2community) algorithm

## Variables

name | description
--- | ---
id | unique code for each row, in case one ever needs it
ac_id_09 | ID code of the assembly segment assigned by the Election Commission (identical with all other post-delimitation codes, hence the _09)
booth_id_17 | ID code of the polling booth assigned by the Election Commission (together with ac_id_09, this should suffice for matching with other tables)
electors_17 | Number of registered electors
missing_percent_17 | Percentage of electors whose names could not be matched by the algorithm (one crude aggregate measure of reliability)
hindu_percent_17 | Estimated percentage of electors who are Hindu
muslim_percent_17 | Estimated percentage of electors who are Muslim
christian_percent_17 | Estimated percentage of electors who are Christian (be aware that accuracy of the algorithm has only been tested for Hindu and Muslim names, not Christian ones)
sikh_percent_17 | Estimated percentage of electors who are Sikh (be aware that accuracy of the algorithm has only been tested for Hindu and Muslim names, not Sikh ones)
jain_percent_17 | Estimated percentage of electors who are Jain (be aware that accuracy of the algorithm has only been tested for Hindu and Muslim names, not Jain ones)
buddhist_percent_17 | Estimated percentage of electors who are Buddhist (be aware that accuracy of the algorithm has only been tested for Hindu and Muslim names, not Buddhist ones)
age_avg_17 | Average age of all electors
age_stddev_17 | Standard deviation of the age distribution of all electors
female_percent_17 | Percentage of female electors among all electors
age_*_avg_17 | Average age of electors estimated to be * (Hindu / Muslim / Christian / Sikh / Jain / Buddhist)
age_*_stddev_17 | Standard deviation of the age distribution of electors  estimated to be * (Hindu / Muslim / Christian / Sikh / Jain / Buddhist)
female_*_percent_17 | Percentage of female electors among electors estimated to be * (Hindu / Muslim / Christian / Sikh / Jain / Buddhist)
revision_percent_new_17 | Percentage of electors added to this booth's rolls in 2017, against the baseline of 2016
revision_percent_deleted_17 | Percentage of electors deleted from this booth's rolls in 2017, against the baseline of 2016
revision_percent_modified_17 | Percentage of electors modified in this booth's rolls in 2017, against the baseline of 2016

## Raw data

Originally, the electoral rolls were crawled in January 2017 from http://ceouttarpradesh.nic.in/_RollPDF.aspx using run-in-arc/downloadpdf.pl; the "last updated on" entry on the rolls' cover sheet reads "1/1/2017".

Raw data itself (electoral roll PDFs as well as the voter-by-voter name classifications derived from them) are not shared here, though, both to save space (it amounts to several GBs of binary dumps) and in light of privacy concerns (electoral rolls are public data, but I doubt that electors like to have their probable religion searchable by EPIC card number). 

The subsequent processing chain is however preserved in the run-in-arc folder for reference. It ran on the [Oxford Advanced Research Computing cluster](https://www.arc.ox.ac.uk) and several hardcoded binary paths as well as the Torque scheduler commands are unique to this environment. After running createnamedb.pl once and putting all additional software in place, the chain was started using run.sh, which basically sparked 403 parallel processes (one for each assembly segment), in which roll PDFs were downloaded, relevant data extracted, names of electors matched to likely religion and ultimately booth-wise estimates of religious demography calculated. 

Because the PDFs were corrupted, though, one could not simply extract non-latin text from them as was the case in earlier years - it came out garbled. Turns out the version of Crystal Reports used in 2014 resulted in wrong ToUnicode CMaps in the PDF - an unfixable problem. Ultimately, I thus settled on an OCR solution - see pdf2list.pl for the gory details (each electoral roll is dissected into tiny TIFFs, which are then fed through tesseract). 

Also, booth IDs did somewhat change between 2014-2016 and 2017 - ever so slightly in most assembly segments, but they did change. One or two of them did. Grrrh. To help compress the upid table later on (and calculate revision_percent_*_17 variables), I compared the voter IDs in the 2016 rolls to those of the 2017 rolls - and if they highly overlap assumed that the relevant booths are equivalents (actual integration across years is done by the scripts in the upid table itself through uprolls2017-b.sql).

The final task of pulling everything together for this dataset is delivered by combine.pl, which results in one large booths.sqlite file, which is shared here as .tgz archive (even this is quite large). The SQL code to put this into the main database and create the subsequent CSV dumps was done using transform.pl.

## License

While the database in its entirety is subject to an [ODC Open Database License](http://opendatacommons.org/licenses/odbl/), as explained in the main [README](https://github.com/raphael-susewind/india-religion-politics/blob/master/README.md) and [LICENSE](https://github.com/raphael-susewind/india-religion-politics/blob/master/LICENSE.md) files, the content of this specific table as well as code used for crawling and compilation is subject to a [CC-BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) license: you can use it for non-commercial purposes as long as you attribute and share any additions or modifications on equal terms. 
