ATTACH '2009/booths-locality.sqlite' AS booths2009;
ATTACH '2012/booths-locality.sqlite' AS booths2012;
ATTACH '2014/booths-locality.sqlite' AS booths2014;
CREATE TABLE upgis (ac_id_09 INTEGER, booth_id_09 INTEGER, booth_name_09 CHAR, district_name_09 CHAR, booth_id_12 INTEGER, booth_name_12 CHAR, district_name_12 CHAR, booth_id_14 INTEGER, booth_name_14 CHAR, district_name_14 CHAR, latitude FLOAT, longitude FLOAT);
INSERT INTO upgis (ac_id_09,booth_id_09,booth_name_09,district_name_09,latitude,longitude) SELECT constituency, booth, station_name, district_name, latitude, longitude FROM booths2009.booths;
INSERT INTO upgis (ac_id_09,booth_id_12,booth_name_12,district_name_12,latitude,longitude) SELECT constituency, booth, station_name, district_name, latitude, longitude FROM booths2012.booths;
INSERT INTO upgis (ac_id_09,booth_id_14,booth_name_14,district_name_14,latitude,longitude) SELECT constituency, booth, station_name, district_name, latitude, longitude FROM booths2014.booths;
.once upgis.sql
.dump upgis
.mode csv
.headers on
.once upgis.csv
SELECT * FROM upgis;
