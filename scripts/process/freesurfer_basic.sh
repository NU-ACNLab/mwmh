#!/bin/bash
#SBATCH --account=p31521                                  ## YOUR ACCOUNT pXXXX or bXXXX
#SBATCH --partition=long                                  ## PARTITION (buyin, short, normal, w10001, etc)
#SBATCH --nodes=1                                         ## how many computers do you need
#SBATCH --ntasks-per-node=1                               ## how many cpus or processors do you need on each computer
#SBATCH --time=168:00:00                                  ## how long does this need to run (remember different partitions have restrictions on this param)
#SBATCH --mem-per-cpu=12G                                 ## how much RAM do you need per CPU (this effects your FairShare score so be careful to not ask for more than you need))
#SBATCH --job-name="freesurfer"                           ## use the task id in the name of the job
#SBATCH --mail-type=FAIL                                  ## you can receive e-mail alerts from SLURM when your job begins and when your job finishes (completed, failed, etc)
#SBATCH --mail-user=ellynbutler2027@u.northwestern.edu    ## your email

pwd; hostname; date

# https://fscph.nru.dk/slides/Martin/fs.longitudinal.mr.pdf
# https://github.com/bids-apps/freesurfer

#### CROSS

SINGULARITYENV_SUBJECTS_DIR=/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/ \
    singularity run --writable-tmpfs --cleanenv --containall \
    -B /projects/b1108:/projects/b1108 \
    -B /projects/b1108/software/freesurfer_license/license.txt:/opt/freesurfer/license.txt \
    /projects/b1108/software/singularity_images/freesurfer_7.2.0.sif \
    recon-all -s sub-MWMH358 \
    -i /projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/sub-MWMH358/ses-1/anat/sub-MWMH358_ses-1_T1w.nii.gz \
    -all

SINGULARITYENV_SUBJECTS_DIR=/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/ \
    singularity run --writable-tmpfs --cleanenv --containall \
    -B /projects/b1108:/projects/b1108 \
    -B /projects/b1108/software/freesurfer_license/license.txt:/opt/freesurfer/license.txt \
    /projects/b1108/software/singularity_images/freesurfer_7.2.0.sif \
    recon-all -s sub-MWMH358 \
    -i /projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/sub-MWMH358/ses-2/anat/sub-MWMH358_ses-2_T1w.nii.gz \
    -all


#### BASE

SINGULARITYENV_SUBJECTS_DIR=/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/ \
    singularity run --writable-tmpfs --cleanenv --containall \
    -B /projects/b1108:/projects/b1108 \
    -B /projects/b1108/software/freesurfer_license/license.txt:/opt/freesurfer/license.txt \
    /projects/b1108/software/singularity_images/freesurfer_7.2.0.sif \
    recon-all -base -tp -all


#### LONG

SINGULARITYENV_SUBJECTS_DIR=/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/ \
    singularity run --writable-tmpfs --cleanenv --containall \
    -B /projects/b1108:/projects/b1108 \
    -B /projects/b1108/software/freesurfer_license/license.txt:/opt/freesurfer/license.txt \
    /projects/b1108/software/singularity_images/freesurfer_7.2.0.sif \
    recon-all -long -all


#sbatch -o /projects/b1108/studies/mwmh/launch/freesurfer/test.txt /projects/b1108/studies/mwmh/scripts/process/freesufer_basic.sh
