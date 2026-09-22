-- Regenerate the CSV dumps from a finished combined.sqlite:
--   sqlite3 combined.sqlite < export.sql
-- Files are written to export/, never over the CSVs that are part of the repository.
.bail on
.system mkdir -p export
.mode csv
.headers on

-- from upvidhansabha2007/upvidhansabha2007-a.sql
.once export/upvidhansabha2007.csv
SELECT * FROM upvidhansabha2007;

-- from uploksabha2009/uploksabha2009-c.sql
.once export/uploksabha2009-a.csv
SELECT * FROM uploksabha2009 LIMIT 50000;
.once export/uploksabha2009-b.csv
SELECT * FROM uploksabha2009 LIMIT 50000 OFFSET 50000;
.once export/uploksabha2009-c.csv
SELECT * FROM uploksabha2009 LIMIT -1 OFFSET 100000;

-- from upvidhansabha2012/upvidhansabha2012-d.sql
.once export/upvidhansabha2012-a.csv
SELECT * FROM upvidhansabha2012 LIMIT 40000;
.once export/upvidhansabha2012-b.csv
SELECT * FROM upvidhansabha2012 LIMIT 40000 OFFSET 40000;
.once export/upvidhansabha2012-c.csv
SELECT * FROM upvidhansabha2012 LIMIT -1 OFFSET 80000;

-- from uploksabha2014/uploksabha2014-c.sql
.once export/uploksabha2014.csv
SELECT * FROM uploksabha2014;

-- from upvidhansabha2017/upvidhansabha2017-g.sql
.once export/upvidhansabha2017.csv
SELECT * FROM upvidhansabha2017;

-- from uprolls2012/uprolls2012.sql
.once export/uprolls2012.csv
SELECT * FROM uprolls2012;

-- from uprolls2017/uprolls2017-a.sql
.once export/uprolls2017.csv
SELECT * FROM uprolls2017;

-- from upcandidates2007/upcandidates2007.sql
.once export/upcandidates2007.csv
SELECT * FROM upcandidates2007;

-- from upcandidates2009/upcandidates2009.sql
.once export/upcandidates2009.csv
SELECT * FROM upcandidates2009;

-- from upcandidates2012/upcandidates2012.sql
.once export/upcandidates2012.csv
SELECT * FROM upcandidates2012;

-- from upcandidates2014/upcandidates2014.sql
.once export/upcandidates2014.csv
SELECT * FROM upcandidates2014;

-- from upcandidates2017/upcandidates2017.sql
.once export/upcandidates2017.csv
SELECT * FROM upcandidates2017;

-- from gujloksabha2014/gujloksabha2014-a.sql
.once export/gujloksabha2014.csv
SELECT * FROM gujloksabha2014;

-- from gujcandidates2014/gujcandidates2014.sql
.once export/gujcandidates2014.csv
SELECT * FROM gujcandidates2014;

-- from delhirolls2021/delhirolls2021-a.sql
.once export/delhirolls2021.csv
SELECT * FROM delhirolls2021;

-- from harrolls2021/harrolls2021-a.sql
.once export/harrolls2021.csv
SELECT * FROM harrolls2021;

-- from wbrolls2014/wbrolls2014-a.sql
.once export/wbrolls2014.csv
SELECT * FROM wbrolls2014;

-- from wbrolls2021/wbrolls2021-a.sql
.once export/wbrolls2021.csv
SELECT * FROM wbrolls2021;

-- from upid/upid-b.sql
.once export/upid-a.csv
SELECT * FROM upid LIMIT 90000;
.once export/upid-b.csv
SELECT * FROM upid LIMIT -1 OFFSET 90000;

-- from gujid/gujid-b.sql
.once export/gujid.csv
SELECT * FROM gujid;

-- from andhraid/andhraid-b.sql
.once export/andhraid.csv
SELECT * FROM andhraid;

-- from delhiid/delhiid-b.sql
.once export/delhiid.csv
SELECT * FROM delhiid;

-- from harid/harid-b.sql
.once export/harid.csv
SELECT * FROM harid;

-- from karid/karid-b.sql
.once export/karid.csv
SELECT * FROM karid;

-- from kerid/kerid-b.sql
.once export/kerid.csv
SELECT * FROM kerid;

-- from mpid/mpid-b.sql
.once export/mpid.csv
SELECT * FROM mpid;

-- from mahaid/mahaid-b.sql
.once export/mahaid.csv
SELECT * FROM mahaid;

-- from orid/orid-b.sql
.once export/orid.csv
SELECT * FROM orid;

-- from rajid/rajid-b.sql
.once export/rajid.csv
SELECT * FROM rajid;

-- from wbid/wbid-b.sql
.once export/wbid.csv
SELECT * FROM wbid;

-- from goaid/goaid-b.sql
.once export/goaid.csv
SELECT * FROM goaid;
