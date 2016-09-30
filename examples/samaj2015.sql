.mode csv
.headers on
.once samaj2015.csv
SELECT 
upgis.latitude 'latitude',
upgis.longitude 'longitude',
uprolls2014.muslim_percent_14 'muslim_percent'
FROM upgis 
JOIN uprolls2014 ON upgis.ac_id_09 = uprolls2014.ac_id_09 AND upgis.booth_id_14 = uprolls2014.booth_id_14
WHERE upgis.ac_id_09 BETWEEN 168 AND 176
;
