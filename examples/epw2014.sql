CREATE INDEX gujstation14 ON gujid (station_id_14);

.mode csv
.headers on
.once gujarat.csv

SELECT 
gujid.pc_id_09 'pc',
gujid.pc_name_09 'pc_name',
gujid.ac_id_09 'ac',
gujid.ac_name_14 'ac_name',
gujid.booth_id_14 'booth',
gujid.station_id_14 'station',
( SELECT count(*) FROM gujid subgujid WHERE subgujid.station_id_14 = gujid.station_id_14 ) 'boothcount',
gujrolls2014.electors_14 'electors',
gujrolls2014.age_avg_14 'age_avg',
gujrolls2014.women_percent_14 'women_percent',
cast((gujrolls2014.muslim_percent_14 * gujrolls2014.electors_14 / 100) as integer) 'muslims',
gujrolls2014.muslim_percent_14 'muslim_percent',
gujloksabha2014.turnout_14 'total_votes',
gujloksabha2014.turnout_percent_14 'turnout_percent',
gujcandidates2014.candidate_bharatiyajanataparty_religion_14 'bjp_candidate_religion',
gujloksabha2014.votes_bjp_14 'bjp_votes',
gujcandidates2014.candidate_indiannationalcongress_religion_14 'inc_candidate_religion',
gujloksabha2014.votes_inc_14 'inc_votes',
gujcandidates2014.candidate_aamaadmiparty_religion_14 'aap_candidate_religion',
gujloksabha2014.votes_aamaadmiparty_14 'aap_votes'
FROM gujid gujid
LEFT JOIN gujrolls2014 ON gujid.ac_id_09 = gujrolls2014.ac_id_09 and gujid.booth_id_14 = gujrolls2014.booth_id_14
LEFT JOIN gujloksabha2014 ON gujid.ac_id_09 = gujloksabha2014.ac_id_09 and gujid.booth_id_14 = gujloksabha2014.booth_id_14
LEFT JOIN gujcandidates2014 ON gujid.pc_id_09 = gujcandidates2014.pc_id_14
WHERE gujid.booth_id_14 IS NOT NULL AND gujid.ac_id_09 IS NOT NULL
;

CREATE INDEX upstation14 ON upid (station_id_14);

.mode csv
.headers on
.once uttarpradesh.csv

SELECT 
upid.pc_id_09 'pc',
upid.pc_name_09 'pc_name',
upid.ac_id_09 'ac',
upid.ac_name_14 'ac_name',
upid.booth_id_14 'booth',
upid.station_id_14 'station',
( SELECT count(*) FROM upid subupid WHERE subupid.station_id_14 = upid.station_id_14 ) 'boothcount',
uprolls2014.electors_14 'electors',
uprolls2014.age_avg_14 'age_avg',
uprolls2014.women_percent_14 'women_percent',
cast((uprolls2014.muslim_percent_14 * uprolls2014.electors_14 / 100) as integer) 'muslims',
uprolls2014.muslim_percent_14 'muslim_percent',
uploksabha2014.turnout_14 'total_votes',
uploksabha2014.turnout_percent_14 'turnout_percent',
upcandidates2014.candidate_bharatiyajanataparty_religion_14 'bjp_candidate_religion',
uploksabha2014.votes_bjp_14 'bjp_votes',
upcandidates2014.candidate_indiannationalcongress_religion_14 'inc_candidate_religion',
uploksabha2014.votes_inc_14 'inc_votes',
upcandidates2014.candidate_sp_religion_14 'sp_candidate_religion',
uploksabha2014.votes_sp_14 'sp_votes',
upcandidates2014.candidate_bsp_religion_14 'bsp_candidate_religion',
uploksabha2014.votes_bsp_14 'bsp_votes',
upcandidates2014.candidate_aamaadmiparty_religion_14 'aap_candidate_religion',
uploksabha2014.votes_aamaadmiparty_14 'aap_votes'
FROM upid upid
LEFT JOIN uprolls2014 ON upid.ac_id_09 = uprolls2014.ac_id_09 and upid.booth_id_14 = uprolls2014.booth_id_14
LEFT JOIN uploksabha2014 ON upid.ac_id_09 = uploksabha2014.ac_id_09 and upid.booth_id_14 = uploksabha2014.booth_id_14
LEFT JOIN upcandidates2014 ON upid.pc_id_09 = upcandidates2014.pc_id_14
WHERE upid.booth_id_14 IS NOT NULL AND upid.ac_id_09 IS NOT NULL
;
