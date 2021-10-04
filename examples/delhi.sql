SELECT load_extension('/usr/src/sqlite-regex-replace-ext/icu_replace.so', 'sqlite3_extension_init');
.mode csv
.headers on
.once delhi.csv
SELECT 
avg(delhigis.latitude) 'latitude',
avg(delhigis.longitude) 'longitude',
avg(delhirolls2014.muslim_percent_14) 'muslim14',
avg(delhirolls2014.missing_percent_14) 'missing14',
avg(delhirolls2021.muslim_percent_21) 'muslim21',
avg(delhirolls2021.missing_percent_21) 'missing21',
avg(delhirolls2021.muslim_percent_21)-avg(delhirolls2014.muslim_percent_14) 'muslimdiff',
avg(delhirolls2021.missing_percent_21)-avg(delhirolls2014.missing_percent_14) 'missingdiff',
trim(regex_replace(',',regex_replace('Room',regex_replace('No',regex_replace('\d+',delhigis.booth_name_14, ''),''),''),'')) 'station_name'
FROM delhiid 
LEFT JOIN delhigis ON delhiid.ac_id_09 = delhigis.ac_id_09 AND delhiid.booth_id_14 = delhigis.booth_id_14
LEFT JOIN delhirolls2014 ON delhiid.ac_id_09 = delhirolls2014.ac_id_09 AND delhiid.booth_id_14 = delhirolls2014.booth_id_14
LEFT JOIN delhirolls2021 ON delhiid.ac_id_09 = delhirolls2021.ac_id_09 AND delhiid.booth_id_21 = delhirolls2021.booth_id_21
GROUP BY latitude,longitude
;
