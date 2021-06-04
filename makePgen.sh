#!/bin/bash

#to run this job: sbatch /pl/active/IBG/promero/annotScripts/makePgen.sh
#Purpose: turn bgen files into pgen for faster splitting files later (accompanies splotPgen.sh script). 

######################
# 0: Setup with Blanca
######################

#SBATCH --time 4:00:00        # Walltime
#SBATCH --qos=preemptable     # Quality of Service
##SBATCH --mem=80gb           # Total amount of memory to allocate
#SBATCH --ntasks 12           # Number of CPUs
##SBATCH --nodes=1
#SBATCH --array 1-20          # Number of jobs
#SBATCH --output=/rc_scratch/paro1093/plink_bgen_03dos/makePgen_chr%a.out

#0: Set up:
#------------
#Get start_time:
start_time=`date +%s`
echo "Start time:" $start_time

#Get job array member:
jobnum="${SLURM_ARRAY_TASK_ID}"
echo "Making pgen for chr:" $jobnum

#Export path to software/clean environment:
ml purge
export PATH=/pl/active/KellerLab/opt/bin:$PATH

#1: Set variables:
#----------------------------------------------
cd /rc_scratch/paro1093/plink_bgen_03dos

prefix="/work/IBG/spaul/UKB_EUR_QC/bgen/chr"
postfix="03dosHRC"
chr=${SLURM_ARRAY_TASK_ID}

######################
# 1: Make pgen files
######################

plink2 \
  --bgen ${prefix}${chr}.bgen ref-first \
  --sample ${prefix}${chr}.sample \
  --make-pgen \
  --threads 12 \
  --out ${postfix}${chr}

######################
# 2: Rundown:
######################
echo "Process complete"
echo "Total runtime: $((($(date +%s)-$start_time)/60)) minutes"
