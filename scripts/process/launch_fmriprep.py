### This script generates submission scripts for fmriprep for the first visit
###
### Ellyn Butler
### December 10, 2021


import os
import shutil
import re
import numpy as np

indir = '/projects/b1108/data/MWMH/bids_directory/'
outdir = '/projects/b1108/data/MWMH/fmriprep/'
launchdir = '/projects/b1108/data/MWMH/launch/fmriprep/'

subjs = os.listdir(indir)

for subj in subjs:
    if not os.path.exists(outdir+subj):
        os.mkdir(outdir+subj)
    unprocessed_sessions = np.setdiff1d(os.listdir(indir+subj), os.listdir(outdir+subj))
    for ses in unprocessed_sessions:
        if not os.path.exists(outdir+subj+'/'+ses):
            os.mkdir(outdir+subj+'/'+ses)
        ses_indir = indir+subj+'/'+ses
        ses_outdir = outdir+subj+'/'+ses
        participant_label = subj.split('-')[1]
        cmd = ['SINGULARITYENV_TEMPLATEFLOW_HOME=/home/fmriprep/.cache/templateflow',
            'singularity', 'run', '--cleanenv', '--containall',
            '-B /projects/b1108:/projects/b1108',
            '-B /projects/b1108/software/freesurfer_license/license.txt:/opt/freesurfer/license.txt',
            '-B /projects/b1108/templateflow:/home/fmriprep/.cache/templateflow',
            '/home/erb9722/fmriprep_20.2.3.sif', '/projects/b1108/data/MWMH/bids_directory',
            '/projects/b1108/data/MWMH', 'participant', '--participant-label',
            participant_label, '--fs-no-reconall',
            '--fs-license-file /opt/freesurfer/license.txt',
            '--output-spaces MNI152NLin6Asym', '--skull-strip-template OASIS30ANTs',
            '--bids-filter-file', '/projects/b1108/data/MWMH/config/'+ses+'_config.json']
        fmriprep_script = launchdir+sub+'_'+ses+'_fmriprep_run.sh'
        os.system('echo ')
        os.system('echo '+' '.join(cmd)+' > '+fmriprep_script)
        os.system('chmod +x '+fmriprep_script)
        os.system('bsub '+fmriprep_script)


        SINGULARITYENV_TEMPLATEFLOW_HOME=/home/fmriprep/.cache/templateflow \
            singularity run --cleanenv --containall \
            -B /projects/b1108:/projects/b1108 \
            -B /projects/b1108/software/freesurfer_license/license.txt:/opt/freesurfer/license.txt \
            -B /projects/b1108/templateflow:/home/fmriprep/.cache/templateflow \
            /home/erb9722/fmriprep_20.2.3.sif \
            /projects/b1108/data/MWMH/bids_directory /projects/b1108/data/MWMH \
            participant --participant-label MWMH117 \
            --fs-no-reconall \
            -w /projects/b1108/data/MWMH/work \
            --fs-license-file /opt/freesurfer/license.txt \
            --output-spaces MNI152NLin6Asym \
            --skull-strip-template OASIS30ANTs \
            --bids-filter-file /projects/b1108/data/MWMH/config/ses-1_config.json
