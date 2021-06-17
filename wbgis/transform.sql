ATTACH 'booths-locality-modis.sqlite' AS booths2014;
ATTACH 'westbengal-gis-2021.sqlite' AS booths2021;
CREATE TABLE wbgis (ac_id_09 INTEGER, booth_id_14 INTEGER, booth_name_14 CHAR, district_name_14 CHAR, latitude FLOAT, longitude FLOAT, modis CHAR, modis_rank INTEGER, district_id_21 INTEGER, district_name_21 CHAR, ac_name_21 CHAR, booth_id_21 INTEGER, booth_name_21 CHAR, section_name_21 CHAR, para_name_21 CHAR, pincode_21 INTEGER, policestation_21 CHAR, postoffice_21 CHAR);
INSERT INTO wbgis (ac_id_09,booth_id_14,booth_name_14,district_name_14,latitude,longitude,modis,modis_rank) SELECT constituen, booth, station_na, district_n, latitude, longitude,featurecla,scalerank FROM booths2014.booths_locality_modis;
INSERT INTO wbgis (district_id_21, district_name_21, ac_id_09, ac_name_21, booth_id_21, booth_name_21, section_name_21, para_name_21, pincode_21, policestation_21, postoffice_21, latitude, longitude) SELECT district_id_21, district_name_21, ac_id_09, ac_name_21, booth_id_21, booth_name_21, section_name_21, para_name_21, pincode_21, policestation_21, postoffice_21, latitude, longitude FROM booths2021.wbgis GROUP BY ac_id_09,booth_id_21;
.once wbgis.sql
.dump wbgis
.mode csv
.headers on
.once wbgis.csv
SELECT * FROM wbgis;
