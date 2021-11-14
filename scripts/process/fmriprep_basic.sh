singularity run --cleanenv /home/erb9722/fmriprep_20.2.3.sif \
    /projects/b1108/data/MWMH/bids_directory /projects/b1108/data/MWMH/fmriprep \
    participant \
    --participant-label MWMH001 --fs-license-file /home/erb9722/license.txt \
    --bids-filter-file /projects/b1108/data/MWMH/config/ses-1_config.json
