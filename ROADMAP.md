# Data on religion and politics in India

This roadmap is a reminder to myself what I aim to achieve over the next couple of months (I am not giving firm dates here, out of experience...). I put it online just in case anyone stumbles across it and is willing / able to contribute (I particularly think of form20 results, which tend to be a major hassle to scrape)

## First proper release

For the first official release of this dataset, I aim to import and double-check all Uttar Pradesh data that was formerly hosted on my personal website. Specifically, these tasks are still open:

* Add actual data from rolls in 2012 and 2013 and double check lastupdate for both
* Add frontpage stuff from rolls in 2014 (which might be slightly different from 2011-13)
* Add psname2partname mapping for 2014 into upid
* Add polling booth locality data for 2009, 2012 and 2014 into upid
* Add MODIS 500m rural/urban classification for booth localities to upid
* Add PC IDs and names to upid
* Integrate the upid rows using old code updated to cover 2014 as well, and preferably taking into account booth details from first pages, psname2partname as well as spatial data - well actually, just rewrite the whole integration script if I am honest...

## Second proper release

Once UP is dealt with properly, I will expand to all-India level for the 2014 general elections. Namematching might not cover all states because it eats tons of resources - lets see. Anyway, this would be desirable:

* Add 2014 Lok Sabha booth level results for more states (to the extent that it is halfway easily accessible)
* Add namematching data from electoral rolls for 2014 across more states (about half of them done already)
* Add candidate name, party and likely religion for 2014 in separate candidate tables
* Add polling booth locality data for 2014 across India (from my GIS dataset, practically done)
* Add MODIS 500m rural/urban classification for booth localities 

## Third proper release

As a more distant goal - and only if I find time before the UP 2017 elections consume all of my energy - I aim to take an experimental shot at integration booth-level electoral and village-level Census data. I already have a processing chain built up, but need to find a way to verify the results' quality before moving ahead with it. Ideally, though, the following should be added across India:

* Match 2014 booth IDs to Census 2001 and Census 2011 village / ward IDs
* Merge with the whole administrative hierarchy up to district level
* If copyright permits, match in MOSPI data as well as village-level Census data and/or PCAs on higher administrative units
* Add namematched BPL data (which is tied in with admin boundaries)