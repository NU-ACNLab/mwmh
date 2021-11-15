#!/bin/bash
#SBATCH --account=b1081                                   ## YOUR ACCOUNT pXXXX or bXXXX
#SBATCH --partition=buyin                                 ## PARTITION (buyin, short, normal, w10001, etc)
#SBATCH --array=1                                         ## number of jobs to run "in parallel"
#SBATCH --nodes=1                                         ## how many computers do you need
#SBATCH --ntasks-per-node=1                               ## how many cpus or processors do you need on each computer
#SBATCH --time=30:10:00                                   ## how long does this need to run (remember different partitions have restrictions on this param)
#SBATCH --mem-per-cpu=64G                                 ## how much RAM do you need per CPU (this effects your FairShare score so be careful to not ask for more than you need))
#SBATCH --job-name="/projects/b1108/data/MWMH/fmriprep_launch/sample_job_\${SLURM_ARRAY_TASK_ID}"   ## use the task id in the name of the job
#SBATCH --output=sample_job.%A_%a.out                     ## use the jobid (A) and the specific job index (a) to name your log file
#SBATCH --mail-type=FAIL                                  ## you can receive e-mail alerts from SLURM when your job begins and when your job finishes (completed, failed, etc)
#SBATCH --mail-user=ellynbutler2027@u.northwestern.edu    ## your email

pwd; hostname; date

singularity run --cleanenv -B /projects/b1108/data/MWMH \
    /home/erb9722/fmriprep_20.2.3.sif \
    /projects/b1108/data/MWMH/bids_directory /projects/b1108/data/MWMH \
    participant \
    --participant-label MWMH001 --fs-license-file /home/erb9722/license.txt \
    --bids-filter-file /projects/b1108/data/MWMH/config/ses-1_config.json
