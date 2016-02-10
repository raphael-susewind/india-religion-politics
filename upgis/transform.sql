ATTACH '2009/booths-locality-modis.sqlite' AS booths2009;
ATTACH '2012/booths-locality-modis.sqlite' AS booths2012;
ATTACH '2014/booths-locality-modis.sqlite' AS booths2014;
CREATE TABLE upgis (ac_id_09 INTEGER, booth_id_09 INTEGER, booth_name_09 CHAR, district_name_09 CHAR, booth_id_12 INTEGER, booth_name_12 CHAR, district_name_12 CHAR, booth_id_14 INTEGER, booth_name_14 CHAR, district_name_14 CHAR, latitude FLOAT, longitude FLOAT, modis CHAR, modis_rank INTEGER);
INSERT INTO upgis (ac_id_09,booth_id_09,booth_name_09,district_name_09,latitude,longitude,modis,modis_rank) SELECT constituen, booth, station_na, district_n, latitude, longitude,featurecla,scalerank FROM booths2009.booths_locality_modis;
INSERT INTO upgis (ac_id_09,booth_id_12,booth_name_12,district_name_12,latitude,longitude,modis,modis_rank) SELECT constituen, booth, station_na, district_n, latitude, longitude,featurecla,scalerank FROM booths2012.booths_locality_modis;
INSERT INTO upgis (ac_id_09,booth_id_14,booth_name_14,district_name_14,latitude,longitude,modis,modis_rank) SELECT constituen, booth, station_na, district_n, latitude, longitude,featurecla,scalerank FROM booths2014.booths_locality_modis;
.once upgis.sql
.dump upgis
.mode csv
.headers on
.once upgis.csv
SELECT * FROM upgis;
