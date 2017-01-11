# Data on religion and politics in India 

## uprolls2015

This table contains booth-level estimates of religious demography based on the connotations of electors' names in the electoral rolls of Uttar Pradesh (revision 2015), using an optimized version of my [name2community](https://github.com/raphael-susewind/name2community) algorithm

## Variables

name | description
--- | ---
id | unique code for each row, in case one ever needs it
ac_id_09 | ID code of the assembly segment assigned by the Election Commission (identical with all other post-delimitation codes, hence the _09)
booth_id_14 | ID code of the polling booth assigned by the Election Commission (together with ac_id_09, this should suffice for matching with other tables)
electors_15 | Number of registered electors
missing_percent_15 | Percentage of electors whose names could not be matched by the algorithm (one crude aggregate measure of reliability)
hindu_percent_15 | Estimated percentage of electors who are Hindu
muslim_percent_15 | Estimated percentage of electors who are Muslim
christian_percent_15 | Estimated percentage of electors who are Christian (be aware that accuracy of the algorithm has only been tested for Hindu and Muslim names, not Christian ones)
sikh_percent_15 | Estimated percentage of electors who are Sikh (be aware that accuracy of the algorithm has only been tested for Hindu and Muslim names, not Sikh ones)
jain_percent_15 | Estimated percentage of electors who are Jain (be aware that accuracy of the algorithm has only been tested for Hindu and Muslim names, not Jain ones)
buddhist_percent_15 | Estimated percentage of electors who are Buddhist (be aware that accuracy of the algorithm has only been tested for Hindu and Muslim names, not Buddhist ones)
age_avg_15 | Average age of all electors
age_stddev_15 | Standard deviation of the age distribution of all electors
female_percent_15 | Percentage of female electors among all electors
age_*_avg_15 | Average age of electors estimated to be * (Hindu / Muslim / Christian / Sikh / Jain / Buddhist)
age_*_stddev_15 | Standard deviation of the age distribution of electors  estimated to be * (Hindu / Muslim / Christian / Sikh / Jain / Buddhist)
female_*_percent_15 | Percentage of female electors among electors estimated to be * (Hindu / Muslim / Christian / Sikh / Jain / Buddhist)
revision_percent_new_15 | Percentage of electors added to this booth's rolls in 2015, against the baseline of 2014
revision_percent_deleted_15 | Percentage of electors deleted from this booth's rolls in 2015, against the baseline of 2014
revision_percent_modified_15 | Percentage of electors modified in this booth's rolls in 2015, against the baseline of 2014

## Raw data

Originally, the electoral rolls were crawled in August 2016 from http://ceouttarpradesh.nic.in/_RollPDF.aspx using run-in-osc/downloadpdf.pl; the "last updated on" entry on the rolls' cover sheet reads "1/1/2014", but the PDFs included later additions for 2015 and 2016 roll revisions (each dated on 1st January for that particular year).

Raw data itself (electoral roll PDFs as well as the voter-by-voter name classifications derived from them) are not shared here, though, both to save space (it amounts to several GBs of binary dumps) and in light of privacy concerns (electoral rolls are public data, but I doubt that electors like to have their probable religion searchable by EPIC card number). 

The subsequent processing chain is however preserved in the run-in-arc folder of the [uprolls2016](https://github.com/raphael-susewind/india-religion-politics/blob/master/uprolls2016) table (from where it originally ran, processing 2015 and 2016 in one go).

Fortunately, at least booth IDs did not change between 2014 and 2015, so this table uses the same IDs as those in use for the 2014 General Elections.

The final task of pulling everything together for this dataset is delivered by combine.pl, which results in one large booths.sqlite file, which is shared here as .tgz archive (even this is quite large). The SQL code to put this into the main database and create the subsequent CSV dumps was done using transform.pl.

## License

While the database in its entirety is subject to an [ODC Open Database License](http://opendatacommons.org/licenses/odbl/), as explained in the main [README](https://github.com/raphael-susewind/india-religion-politics/blob/master/README.md) and [LICENSE](https://github.com/raphael-susewind/india-religion-politics/blob/master/LICENSE.md) files, the content of this specific table as well as code used for crawling and compilation is subject to a [CC-BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) license: you can use it for non-commercial purposes as long as you attribute and share any additions or modifications on equal terms. 
