#!/bin/sh

export GRASSFOLDER=.

# Create GRASSRC
echo "GISDBASE: $GRASSFOLDER
LOCATION_NAME: LOCATION 
MAPSET: PERMANENT
" > GRASSRC

# $GISBASE points to the GRASS installation to be used:
export GISBASE=/usr/lib/grass64

# Extend $PATH for the default GRASS scripts:
export PATH=$PATH:$GISBASE/bin:$GISBASE/scripts

# Add GRASS library information:
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$GISBASE/lib

# use process ID (PID) as lock file number:
export GIS_LOCK=$$

# path to GRASS settings file:
export GISRC=$GRASSFOLDER/GRASSRC
	   
g.proj -c epsg=4326 location=LOCATION
g.mapset mapset=PERMANENT location=LOCATION

R CMD BATCH epa2017.R

rm -r -f LOCATION
