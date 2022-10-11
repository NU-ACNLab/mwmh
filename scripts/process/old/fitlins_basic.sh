### This script gives a basic call to fitlins for first level modeling
###
### Ellyn Butler
### May 11, 2022



SINGULARITYENV_TEMPLATEFLOW_HOME=/home/fmriprep/.cache/templateflow \
        singularity run --writable-tmpfs --cleanenv --containall \
        -B /tmp:/tmp -B /projects/b1108:/projects/b1108 \
        -B /projects/b1108/software/freesurfer_license/license.txt:/opt/freesurfer/license.txt \
        /projects/b1108/software/singularity_images/fitlins_0.10.1.sif \
        /projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/ \
        /projects/b1108/studies/mwmh/data/processed/neuroimaging/fitlins/ \
        -w /projects/b1108/studies/mwmh/data/processed/neuroimaging/work/ \
        -d /projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep/ \
        --participant-label MWMH378 \
        -m \
        --space MNI152NLin6Asym \
