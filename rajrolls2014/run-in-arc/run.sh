#!/bin/bash

# set cpu requirement
#PBS -l nodes=1

# set max wallclock time MAXIMUM 100 hours
#PBS -l walltime=120:00:00

# set name of job
#PBS -N rajasthan

# mail alert at start, end and abortion of executio
#PBS -M raphael.susewind@area.ox.ac.uk
#PBS -m bea

# use submission environment
#PBS -V

# start job from the directory it was submitted

module load python/3.4
module load tesseract/svn__19-May-2014

export PATH=$HOME/bin:$PATH

cd $PBS_O_WORKDIR
perl -Mlocal::lib -I$HOME/perl5/lib/perl5 control.pl $PBS_ARRAYID
