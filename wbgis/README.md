# Data on religion and politics in India 

## wbgis

This table contains GIS coordinates and other spatial characteristics of polling booths in West Bengal

## Variables

name | description
--- | ---
ac_id_09 | ID code of the assembly segment assigned by the Election Commission (identical with all other post-delimitation codes, hence the _09)
booth_id_14 | ID code of the polling booth assigned by the Election Commission for 2014 booths (together with ac_id_09, this should suffice for matching with other tables)
booth_name_14 | Name of the polling booth assigned by the Election Commission for 2014 booths
district_name_14 | Name of the district into which this polling booth is supposed to fall in 2014 (could be used for cleaning the data)
district_id_21 | ID of the district into which this polling booth is supposed to fall in 2021 (could be used for cleaning the data)
district_name_21 | Name of the district into which this polling booth is supposed to fall in 2021 (could be used for cleaning the data)
ac_name_21 | Name of the assembly segment in use in 2021 
booth_id_21 | ID code of the polling booth assigned by the Election Commission for 2021 booths (together with ac_id_09, this should suffice for matching with other tables)
booth_name_21 | Name of the polling booth assigned by the Election Commission for 2021 booths
section_name_21 | Name of the section in use in 2021 
para_name_21 | Name of the neighborhood in use in 2021 
pincode_21 | Pincode in use in 2021 
policestation_21 | Name of the relevant police station jurisdiction in 2021 
postoffice_21 | Name of the relevant post office in 2021 
latitude | Geographical latitude
longitude | Geographical longitude
modis | Urban area or not? Derived from MODIS polygon (see below)
modis_rank | How urban? MODIS Scalerank (see below)

## Raw data

The 2014 data was originally scraped using the Firefox MozRepl plugin in conjunction with download.pl and the custom proxy server at proxy.pl on May 5, 2014 from "http://www.eci-polldaymonitoring.nic.in/psleci. The data used here is NOT cleaned up, and quality varies from district to district, so you need to be careful. The ID codes are the same used for the 2014 Lok Sabha elections. This dataset is identical with the data included in my (more comprehensive) [GIS Shapefiles](http://dx.doi.org/10.4119/unibi/2674065).

All three sets of point data were then dumped into CSVs, transformed into ESRI shapefiles using `ogr2ogr booths-locality.shp booths-locality.vrt` and matched manually against the MODIS polygon from [Naturalearth](http://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-urban-area/) using QGIS. The result was then exported back into booths-locality-modis.sqlite.

The 2021 data was not available from psleci.nic.in for West Bengal; hence this was scraped in May 2021 from [a WB-specific platform](https://wbceo.in/wb-pssearch) advertised at the time of the 2021 assembly elections on the CEO website using download2021.pl; this website used geographical search areas to identify booths in this area; to catch as many booths as possible, this was fed with 2014 latitudes/longitudes. Please note that 2014 and 2021 booth IDs are NOT identical!

The final table was put together using `cat transform.sql | sqlite3`.

## License

While the database in its entirety is subject to an [ODC Open Database License](http://opendatacommons.org/licenses/odbl/), as explained in the main [README](https://github.com/raphael-susewind/india-religion-politics/blob/master/README.md) and [LICENSE](https://github.com/raphael-susewind/india-religion-politics/blob/master/LICENSE.md) files, the content of this specific table is factual data, and as such only subject to a simple [ODC Database Contents License](http://opendatacommons.org/licenses/dbcl/) (at the time of scraping, the respective websites did not display any copyright information). Code used for crawling and compilation is subject to a [CC-BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) license. If you use the modis and modis_rank variables, the original authors ask that you additionally attribute then:

> Schneider, A., M. A. Friedl, D. K. McIver, and C. E. Woodcock (2003) Mapping urban areas by fusing multiple sources of coarse resolution remotely sensed data. Photogrammetric Engineering and Remote Sensing, volume 69, pages 1377-1386.

