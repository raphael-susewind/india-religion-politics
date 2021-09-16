#!/bin/bash -l
#SBATCH --job-name=delhinames
#SBATCH --output=delhinames.array.%A.%a
#SBATCH --array=1-70
#SBATCH --time=7-0

mkdir /users/k1639346/ceodelhi.gov.in/Voter-List-2021/$SLURM_ARRAY_TASK_ID
cd /users/k1639346/ceodelhi.gov.in/Voter-List-2021/$SLURM_ARRAY_TASK_ID

module load apps/singularity
module load devtools/python

cp /users/k1639346/ceodelhi.gov.in/Voter-List-2021/run-on-rosalind/* .
perl -CSDA downloadpdf.pl $SLURM-ARRAY_TASK_ID
perl -CSDA transform-to-ocr-pdfs.pl
mkfifo fifo
perl -CSDA subcontrol.pl $SLURM_ARRAY_TASK_ID
