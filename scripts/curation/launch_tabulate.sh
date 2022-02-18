#!/bin/bash
#SBATCH --account=p31521                                  ## YOUR ACCOUNT pXXXX or bXXXX
#SBATCH --partition=normal                                ## PARTITION (buyin, short, normal, w10001, etc)
#SBATCH --array=1                                         ## number of jobs to run "in parallel"
#SBATCH --nodes=1                                         ## how many computers do you need
#SBATCH --ntasks-per-node=1                               ## how many cpus or processors do you need on each computer
#SBATCH --time=30:00:00                                   ## how long does this need to run (remember different partitions have restrictions on this param)
#SBATCH --mem-per-cpu=100G                                ## how much RAM do you need per CPU (this effects your FairShare score so be careful to not ask for more than you need))
#SBATCH --job-name="tabulate_dicom_headers"               ## use the task id in the name of the job
#SBATCH --output=sample_job.%A_%a.out                     ## use the jobid (A) and the specific job index (a) to name your log file
#SBATCH --mail-type=FAIL                                  ## you can receive e-mail alerts from SLURM when your job begins and when your job finishes (completed, failed, etc)
#SBATCH --mail-user=ellynbutler2027@u.northwestern.edu    ## your email

singularity run --writable-tmpfs --cleanenv \
  -B /projects/b1108:/base \
  /home/erb9722/heudiconv_0.9.0.sif \
  --files /base/studies/mwmh/data/raw/neuroimaging/bids/ \
  -s MWMH219 MWMH379 MWMH112 MWMH196 MWMH225 MWMH275 MWMH293 \
  -o /base/studies/mwmh/data/raw/neuroimaging/bids/ -f convertall \
  --grouping all -c none --overwrite


# sbatch -o /projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/tabulate.txt \
# /projects/b1108/studies/mwmh/scripts/curation/launch_tabulate.sh

# February 16, 2022: Trying a subset of subjects because this error hasn't been
# addressed yet, and there isn't a clear place to bind:
# https://github.com/nipy/heudiconv/issues/545
