SELECT load_extension('/usr/src/sqlite-regex-replace-ext/icu_replace.so', 'sqlite3_extension_init');
.mode csv
.headers on
.once kolkata.csv
SELECT 
avg(wbgis.latitude) 'latitude',
avg(wbgis.longitude) 'longitude',
avg(wbrolls2014.muslim_percent_14) 'muslim_percent',
avg(wbrolls2014.missing_percent_14) 'missing_percent',
trim(regex_replace(',',regex_replace('Room',regex_replace('No',regex_replace('\d+',wbgis.booth_name_14, ''),''),''),'')) 'station_name'
FROM wbgis 
LEFT JOIN wbrolls2014 ON wbgis.ac_id_09 = wbrolls2014.ac_id_09 AND wbgis.booth_id_14 = wbrolls2014.booth_id_14
LEFT JOIN wbid ON wbgis.ac_id_09 = wbid.ac_id_09 AND wbgis.booth_id_14 = wbid.booth_id_14
GROUP BY wbgis.ac_id_09, station_name
;
