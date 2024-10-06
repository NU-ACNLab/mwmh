#!/bin/bash
#SBATCH --account=p31521                                  ## YOUR ACCOUNT pXXXX or bXXXX
#SBATCH --partition=long                                  ## PARTITION (buyin, short, normal, w10001, etc)
#SBATCH --nodes=1                                         ## how many computers do you need
#SBATCH --ntasks-per-node=1                               ## how many cpus or processors do you need on each computer
#SBATCH --time=120:00:00                                  ## how long does this need to run (remember different partitions have restrictions on this param)
#SBATCH --mem-per-cpu=200G                                ## how much RAM do you need per CPU (this effects your FairShare score so be careful to not ask for more than you need))
#SBATCH --job-name="estimatetemplate"                     ## use the task id in the name of the job
#SBATCH --mail-type=FAIL                                  ## you can receive e-mail alerts from SLURM when your job begins and when your job finishes (completed, failed, etc)
#SBATCH --mail-user=ellynbutler2027@u.northwestern.edu    ## your email

Rscript /projects/b1108/studies/mwmh/scripts/process/template_Yeo17_MWMH_sub-all_ses-2_task-rest_desc-smepostproc.R

#sbatch -o /projects/b1108/studies/mwmh/data/processed/neuroimaging/launch/template/MWMH_sub-all_ses-2_task-rest_desc-smepostproc.txt /projects/b1108/studies/mwmh/scripts/process/launch_estimate_template_sub-all_ses-2_task-rest_desc-smepostproc.sh