#!/bin/bash
#SBATCH --job-name=sub-MWMH001_ses-1  # Job name
#SBATCH --mail-type=FAIL              # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=ellynbutler2027@u.northwestern.edu     # Where to send mail
#SBATCH --ntasks=1                    # Run on a single CPU
#SBATCH --partition=normal            # Run on a single CPU
#SBATCH --mem=64gb                    # Job memory request
#SBATCH --time=30:00:00               # Time limit hrs:min:sec
#SBATCH --output=serial_test_%j.log   # Standard output and error log
pwd; hostname; date

singularity run --cleanenv /home/erb9722/fmriprep_20.2.3.sif \
    /projects/b1108/data/MWMH/bids_directory /projects/b1108/data/MWMH/fmriprep \
    participant \
    --participant-label MWMH001 --fs-license-file /home/erb9722/license.txt \
    --bids-filter-file /projects/b1108/data/MWMH/config/ses-1_config.json
