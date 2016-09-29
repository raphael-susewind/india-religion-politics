#!/bin/bash

# set cpu requirement
#PBS -l nodes=1

# set max wallclock time MAXIMUM 100 hours
#PBS -l walltime=48:00:00

# set name of job
#PBS -N gujarat-ngram

# mail alert at start, end and abortion of executio
#PBS -M raphael.susewind@area.ox.ac.uk
#PBS -m ea

# use submission environment
#PBS -V

# start job from the directory it was submitted
module unload python
module load python/3.3

cd $PBS_O_WORKDIR
perl -Mlocal::lib=$HOME/perl5 -I$HOME/perl5/lib/perl5 control.pl $PBS_ARRAYID
