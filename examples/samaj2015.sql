.mode csv
.headers on
.once samaj2015.csv
SELECT 
avg(upgis.latitude) 'latitude',
avg(upgis.longitude) 'longitude',
avg(uprolls2014.muslim_percent_14) 'muslim_percent'
FROM upgis 
LEFT JOIN uprolls2014 ON upgis.ac_id_09 = uprolls2014.ac_id_09 AND upgis.booth_id_14 = uprolls2014.booth_id_14
LEFT JOIN upid ON upgis.ac_id_09 = upid.ac_id_09 AND upgis.booth_id_14 = upid.booth_id_14
WHERE upgis.ac_id_09 BETWEEN 168 AND 176
GROUP BY upid.station_id_14
;
