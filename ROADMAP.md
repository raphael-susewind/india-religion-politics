# Data on religion and politics in India

This roadmap is a reminder to myself what I aim to achieve for future releases (no firm timeline, though). I put it online just in case anyone stumbles across it and is willing / able to contribute (I particularly think of form20 results, which tend to be a major hassle to scrape and cleanup)

## UP special interim release:

Sometime this spring, I hope to put UP data up-to-date as people might find it useful. This means:

* Add UP namematching data for 2017 (currently running on ARC servers)
* Add UP form20 results for vidhan sabha 2017
* Add UP candidate names and likely religion for vidhan sabha 2017
* Add updated UP GIS coordinates for 2017 booth IDs

## Second proper release:

As a next step, I intend to expand to all-India level for the 2014 general elections. This would be desirable:

* Add 2014 Lok Sabha booth level results for more states than just UP and Gujarat (to the extent that it is halfway easily accessible)
* Add namematching data from electoral rolls for 2014 across the remaining states (calculation done already, just need to convert to SQL tables and document)
* Add polling booth locality data for 2014 across India (from my GIS dataset, practically done, just need to convert to SQL tables and document)
* Add MODIS 500m rural/urban classification for booth localities (rather than current 1km ones) 
* Wait for a few weeks to see whether any bugs crop up, then make the formal release

## Third proper release:

As a more distant goal - and only if I find time after the UP 2017 elections consumed all of my energy - I aim to take an experimental shot at integration booth-level electoral and village-level Census data. I already have a processing chain built up, but need to find a way to verify the results' quality before moving ahead with it. Ideally, though, the following should be added across India:

* Match 2014 booth IDs to Census 2001 and Census 2011 village / ward IDs (either spatially and/or using the electoral roll front pages), and implicitly with the whole administrative hierarchy up to district level
* If copyright permits, match in MOSPI data as well as village-level Census data and/or PCAs on higher administrative units
* Use this Census data to add weights to my namematching estimates (so that the latter only decide the distribution within a given census tract, not the average) - for electoral analyses, it makes sense to stay with the estimates of the electorate, but for demographic analyses, it might make sense to circumscribe the same by census data in a kind of Bayesian way
* Use the latter weighted data for a beautifully tiled atlas
* Add namematched BPL data (which is also tied in with admin boundaries)
* Wait for a few weeks to see whether any bugs crop up, then make the formal release

