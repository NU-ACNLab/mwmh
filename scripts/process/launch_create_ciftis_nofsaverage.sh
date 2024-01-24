#!/bin/bash
#SBATCH --account=p31521                                  ## YOUR ACCOUNT pXXXX or bXXXX
#SBATCH --partition=long                                  ## PARTITION (buyin, short, normal, w10001, etc)
#SBATCH --nodes=1                                         ## how many computers do you need
#SBATCH --ntasks-per-node=1                               ## how many cpus or processors do you need on each computer
#SBATCH --time=120:00:00                                  ## how long does this need to run (remember different partitions have restrictions on this param)
#SBATCH --mem-per-cpu=30G                                 ## how much RAM do you need per CPU (this effects your FairShare score so be careful to not ask for more than you need))
#SBATCH --job-name="surf"                                 ## use the task id in the name of the job
#SBATCH --mail-type=FAIL                                  ## you can receive e-mail alerts from SLURM when your job begins and when your job finishes (completed, failed, etc)
#SBATCH --mail-user=ellynbutler2027@u.northwestern.edu    ## your email

/projects/b1108/studies/mwmh/scripts/process/create_ciftis_nofsaverage.sh

#sbatch -o '/projects/b1108/studies/mwmh/data/processed/neuroimaging/launch/try_create_ciftis_nofsaverage.txt /projects/b1108/studies/mwmh/scripts/process/launch_create_ciftis_nofsaverage.sh
