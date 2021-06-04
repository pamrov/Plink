#!/bin/sh

#to run this job: sbatch /pl/active/IBG/promero/annotScripts/splitPgen.sh

######################
# 0: Setup with Blanca
######################
#SBATCH --time 6:00:00        # WALLTIME
#SBATCH --qos=preemptable     # QOS
##SBATCH --mem=120gb          # MEMORY
#SBATCH --ntasks 10           # NUM PROCESSES
#SBATCH --nodes=1             # NUM OF NODES
#SBATCH --array 1-22          # NUM OF JOBS
#SBATCH --output=/rc_scratch/paro1093/plink_bgen_03dos/split_chr%a.out

export PATH=/work/KellerLab/opt/bin:$PATH

#############################
# 1: Initialize Key Variables
#############################
#Start here:
echo "Starting Job. Your Slurm Job ID is:" ${SLURM_ARRAY_JOB_ID}
start_time=`date +%s` #get start time:
echo "Start time:" `date +%c`

#Set file extensions, chr to work on, and how big your chunks will be:
prefix=/rc_scratch/paro1093/plink_bgen_03dos/03dosHRC #include full path/prefix of your files
chunkSize=5262 #this will chunk chr1 the biggest one into ~1,000 chunks
postfix=03dosHRC_chr #new file pre-fix only
chr=${SLURM_ARRAY_TASK_ID}

echo "File ${prefix}${chr} by ${chunkSize} SNPs chunk"
echo "Spliting PLINK ${prefix}${chr} into ${chunkSize} file size"

#make a dir for each chr:
if [ ! -d chr${chr} ]; then mkdir -p chr${chr}; fi

#Initialize chunk start and end limits:
snp_start=1
snp_end=$(($snp_start + $chunkSize -1))

cat /rc_scratch/paro1093/plink_bgen_03dos/03dosHRC${chr}.pvar | tail -n +2 > $SLURM_SCRATCH/temp_${chr} #remove header so it doesn't mess calculations.

#Get total number of SNPs and start a chunk counter:
snps_tot=$(wc -l $SLURM_SCRATCH/temp_${chr} | cut -f1 -d " ")
nchunks=1

############################
# 2: Catch any Start Errors
###########################
#Help 1: Can't find plink software:
if [ ! `type -p plink` ];then
  echo "Error: Cannot find PLINK. Make sure PLINK is in your \$PATH";
  exit 1
fi

#Help 2: No input file provided as first argument (prefix):
if [ "${prefix}" == "" ]; then
  echo "Error: no input file"
  exit 1
fi

#Help 3: No chunk size specified as 2nd argument (chunk):
if [ "${chunkSize}" == "" ]; then
  echo "Error: no chunk size"
  exit 1
fi

#Help 4: No output file prefix to append to (postfix):
if [ "${postfix}" == "" ]; then
  echo "Error: need prefix of output"
  exit 1
fi

#Help 5: If file with prefix name doesn't exist, exit:
if [ ! -e ${prefix}${chr}.pvar ];then
  echo "Error: File ${prefix}${chr}.pvar not found"
  exit 1
fi

##############################
# 3: Split Chr into nchunks:
##############################
echo "Extracting chromosome ${chr} position ${snp_start} to ${snp_end}"

#Loop until no SNPs remain:
while [ $snp_end -le $snps_tot ];
do
  #Get start and stop SNPs for this iteration:
  first_snp=`tail -n +${snp_start} $SLURM_SCRATCH/temp_${chr} | head -n 1| awk '{print $3}'`
  last_snp=`tail -n +${snp_end} $SLURM_SCRATCH/temp_${chr} | head -n 1 | awk '{print $3}'`
  echo "First SNP ${first_snp} Last SNP $last_snp"
  #Start splitting:
  plink2  --pfile ${prefix}${chr} \
          --from $first_snp \
          --to $last_snp \
          --threads $SLURM_NTASKS \
          --make-pgen \
          --out /rc_scratch/paro1093/plink_bgen_03dos/chr${chr}/${postfix}_chr${chr}_chunk${nchunks}
  #update counters:
  snp_start=$(($snp_start + ${chunkSize}))
  snp_end=$((${snp_start} + ${chunkSize} - 1))
  nchunks=$(($nchunks+1))
  #update counter if it exceeds bounds:
  if [ $snp_end -gt $snps_tot ];then
    snp_end=${snps_tot};
    echo "Chunk size is past bounds, set to last SNP:" ${snps_tot}
    plink2  --pfile ${prefix}${chr} \
            --from $first_snp \
            --to $last_snp \
            --threads $SLURM_NTASKS \
            --make-pgen \
            --out /rc_scratch/paro1093/plink_bgen_03dos/chr${chr}/${postfix}${chr}_chunk${nchunks}
    break;
  fi
done

##############
# 3: Rundown
##############
echo "Process complete"
echo "Total runtime: $((($(date +%s)-$start_time)/60)) minutes"
