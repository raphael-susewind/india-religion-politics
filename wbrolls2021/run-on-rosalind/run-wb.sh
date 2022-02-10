#!/bin/bash -l
#SBATCH --job-name=wbnames
#SBATCH --output=wbnames.array.%A.%a
#SBATCH --array=1-294
#SBATCH --time=7-0

mkdir /scratch/users/k1639346/ceowestbengal.nic.in/Voter-List-2021/$SLURM_ARRAY_TASK_ID
cd /scratch/users/k1639346/ceowestbengal.nic.in/Voter-List-2021/$SLURM_ARRAY_TASK_ID

module load apps/singularity
module load devtools/python

cp /scratch/users/k1639346/ceowestbengal.nic.in/Voter-List-2021/run-on-rosalind/* .
perl -CSDA downloadpdf.pl $SLURM_ARRAY_TASK_ID
perl -CSDA transform-to-ocr-pdfs-ben.pl
mkfifo fifo
perl -CSDA subcontrol.pl $SLURM_ARRAY_TASK_ID
