#!/bin/bash

# set cpu requirement
#PBS -l nodes=1

# set max wallclock time MAXIMUM 100 hours
#PBS -l walltime=1:00:00

# set name of job
#PBS -N mnni

# mail alert at start, end and abortion of executio
#PBS -M raphael.susewind@area.ox.ac.uk
#PBS -m bea

# use submission environment
#PBS -V

# start job from the directory it was submitted
module unload python
module load python/3.3

cd $PBS_O_WORKDIR
perl -Mlocal::lib -Iperl5/lib/perl5 control.pl $PBS_ARRAYID
