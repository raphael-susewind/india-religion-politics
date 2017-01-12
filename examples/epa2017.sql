.mode csv
.headers on
.once ahmedabad.csv
SELECT 
gujgis.latitude 'latitude',
gujgis.longitude 'longitude',
gujrolls2014.muslim_percent_14 'muslim'
gujrolls2014.electors_14 'electors'
FROM gujgis 
JOIN gujrolls2014 ON gujgis.ac_id_09 = gujrolls2014.ac_id_09 AND gujgis.booth_id_14 = gujrolls2014.booth_id_14
;
.once aligarh.csv
SELECT 
upgis.latitude 'latitude',
upgis.longitude 'longitude',
uprolls2014.muslim_percent_14 'muslim'
uprolls2014.electors_14 'electors'
FROM upgis 
JOIN uprolls2014 ON upgis.ac_id_09 = uprolls2014.ac_id_09 AND upgis.booth_id_14 = uprolls2014.booth_id_14
;
.once bangalore.csv
SELECT 
kargis.latitude 'latitude',
kargis.longitude 'longitude',
karrolls2014.muslim_percent_14 'muslim'
karrolls2014.electors_14 'electors'
FROM kargis 
JOIN karrolls2014 ON kargis.ac_id_09 = karrolls2014.ac_id_09 AND kargis.booth_id_14 = karrolls2014.booth_id_14
;
.once bhopal.csv
SELECT 
mpgis.latitude 'latitude',
mpgis.longitude 'longitude',
mprolls2014.muslim_percent_14 'muslim'
mprolls2014.electors_14 'electors'
FROM mpgis 
JOIN mprolls2014 ON mpgis.ac_id_09 = mprolls2014.ac_id_09 AND mpgis.booth_id_14 = mprolls2014.booth_id_14
;
.once calicut.csv
SELECT 
kergis.latitude 'latitude',
kergis.longitude 'longitude',
kerrolls2014.muslim_percent_14 'muslim'
kerrolls2014.electors_14 'electors'
FROM kergis 
JOIN kerrolls2014 ON kergis.ac_id_09 = kerrolls2014.ac_id_09 AND kergis.booth_id_14 = kerrolls2014.booth_id_14
;
.once cuttack.csv
SELECT 
orgis.latitude 'latitude',
orgis.longitude 'longitude',
orrolls2014.muslim_percent_14 'muslim'
orrolls2014.electors_14 'electors'
FROM orgis 
JOIN orrolls2014 ON orgis.ac_id_09 = orrolls2014.ac_id_09 AND orgis.booth_id_14 = orrolls2014.booth_id_14
;
.output delhi.csv
SELECT 
delhigis.latitude 'latitude',
delhigis.longitude 'longitude',
delhirolls2014.muslim_percent_14 'muslim'
delhirolls2014.electors_14 'electors'
FROM delhigis 
JOIN delhirolls2014 ON delhigis.ac_id_09 = delhirolls2014.ac_id_09 AND delhigis.booth_id_14 = delhirolls2014.booth_id_14
;
SELECT 
hargis.latitude 'latitude',
hargis.longitude 'longitude',
harrolls2014.muslim_percent_14 'muslim'
harrolls2014.electors_14 'electors'
FROM hargis 
JOIN harrolls2014 ON hargis.ac_id_09 = harrolls2014.ac_id_09 AND hargis.booth_id_14 = harrolls2014.booth_id_14
;
SELECT 
upgis.latitude 'latitude',
upgis.longitude 'longitude',
uprolls2014.muslim_percent_14 'muslim'
uprolls2014.electors_14 'electors'
FROM upgis 
JOIN uprolls2014 ON upgis.ac_id_09 = uprolls2014.ac_id_09 AND upgis.booth_id_14 = uprolls2014.booth_id_14
;
.once hyderabad.csv
SELECT 
andhragis.latitude 'latitude',
andhragis.longitude 'longitude',
andhrarolls2014.muslim_percent_14 'muslim'
andhrarolls2014.electors_14 'electors'
FROM andhragis 
JOIN andhrarolls2014 ON andhragis.ac_id_09 = andhrarolls2014.ac_id_09 AND andhragis.booth_id_14 = andhrarolls2014.booth_id_14
;
.once jaipur.csv
SELECT 
rajgis.latitude 'latitude',
rajgis.longitude 'longitude',
rajrolls2014.muslim_percent_14 'muslim'
rajrolls2014.electors_14 'electors'
FROM rajgis 
JOIN rajrolls2014 ON rajgis.ac_id_09 = rajrolls2014.ac_id_09 AND rajgis.booth_id_14 = rajrolls2014.booth_id_14
;
.once lucknow.csv
SELECT 
upgis.latitude 'latitude',
upgis.longitude 'longitude',
uprolls2014.muslim_percent_14 'muslim'
uprolls2014.electors_14 'electors'
FROM upgis 
JOIN uprolls2014 ON upgis.ac_id_09 = uprolls2014.ac_id_09 AND upgis.booth_id_14 = uprolls2014.booth_id_14
;
.once mumbai.csv
SELECT 
mahagis.latitude 'latitude',
mahagis.longitude 'longitude',
maharolls2014.muslim_percent_14 'muslim'
maharolls2014.electors_14 'electors'
FROM mahagis 
JOIN maharolls2014 ON mahagis.ac_id_09 = maharolls2014.ac_id_09 AND mahagis.booth_id_14 = maharolls2014.booth_id_14
;
