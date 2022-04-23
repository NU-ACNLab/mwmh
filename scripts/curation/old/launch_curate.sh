#!/bin/bash
#SBATCH --account=p31521                                  ## YOUR ACCOUNT pXXXX or bXXXX
#SBATCH --partition=normal                                ## PARTITION (buyin, short, normal, w10001, etc)
#SBATCH --array=1                                         ## number of jobs to run "in parallel"
#SBATCH --nodes=1                                         ## how many computers do you need
#SBATCH --ntasks-per-node=1                               ## how many cpus or processors do you need on each computer
#SBATCH --time=10:00:00                                   ## how long does this need to run (remember different partitions have restrictions on this param)
#SBATCH --mem-per-cpu=10G                                 ## how much RAM do you need per CPU (this effects your FairShare score so be careful to not ask for more than you need))
#SBATCH --job-name="curate_mwmh"                          ## use the task id in the name of the job
#SBATCH --output=sample_job.%A_%a.out                     ## use the jobid (A) and the specific job index (a) to name your log file
#SBATCH --mail-type=FAIL                                  ## you can receive e-mail alerts from SLURM when your job begins and when your job finishes (completed, failed, etc)
#SBATCH --mail-user=ellynbutler2027@u.northwestern.edu    ## your email


singularity run --writable-tmpfs --cleanenv --containall \
  -B /projects/b1108/studies/mwmh/data/raw/neuroimaging:/base \
  -B /projects/b1108/studies/mwmh/scripts/curation/heuristic.py:/base/heuristic.py \
  /home/erb9722/heudiconv_0.9.0.sif \
  -d /base/dicoms/sub-{subject}/*/*/*/*/*.dcm \
  -o /base/bids/ \
  -f /base/heuristic.py -s MWMH219 -c dcm2niix -b --overwrite



#https://github.com/nipy/heudiconv/issues/184

# sbatch -o /projects/b1108/studies/mwmh/errors/curate_errors.txt \
# /projects/b1108/studies/mwmh/scripts/curation/launch_curate.sh
