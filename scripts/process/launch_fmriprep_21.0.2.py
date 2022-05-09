### This script generates submission scripts for fmriprep for the first visit
###
### Ellyn Butler
### May 5, 2022


import os
import shutil
import re
import numpy as np
import glob

indir = '/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/'
outdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep/'
launchdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/launch/fmriprep/'

subdirs = glob.glob(indir + "sub-*")

for subdir in subdirs:
    sub = subdir.split('/')[9]
    if not os.path.exists(outdir+sub):
        os.mkdir(outdir+sub)
    unprocessed_sessions = np.setdiff1d(os.listdir(indir+sub), os.listdir(outdir+sub))
    for ses in unprocessed_sessions:
        if not os.path.exists(outdir+sub+'/'+ses):
            os.mkdir(outdir+sub+'/'+ses)
        participant_label = sub.split('-')[1]
        cmd = ['SINGULARITYENV_TEMPLATEFLOW_HOME=/home/fmriprep/.cache/templateflow',
            'singularity', 'run', '--writable-tmpfs', '--cleanenv', '--containall',
            '-B /projects/b1108:/projects/b1108',
            '-B /projects/b1108/software/freesurfer_license/license.txt:/opt/freesurfer/license.txt',
            '-B /projects/b1108/templateflow:/home/fmriprep/.cache/templateflow',
            '/projects/b1108/software/singularity_images/fmriprep_21.0.2.sif',
            indir, outdir, 'participant', '--participant-label',
            participant_label, '--fs-no-reconall',
            '-w /projects/b1108/studies/mwmh/data/processed/neuroimaging/work',
            '--fs-license-file /opt/freesurfer/license.txt',
            '--output-spaces MNI152NLin6Asym', '--skull-strip-template OASIS30ANTs',
            '--bids-filter-file', '/projects/b1108/studies/mwmh/config/'+ses+'_config.json']
        fmriprep_script = launchdir+sub+'_'+ses+'_fmriprep_run.sh'
        os.system('cat /projects/b1108/studies/mwmh/scripts/process/sbatchinfo_general.sh > '+fmriprep_script)
        os.system('echo '+' '.join(cmd)+' >> '+fmriprep_script)
        os.system('chmod +x '+fmriprep_script)
        os.system('sbatch -o '+launchdir+sub+'_'+ses+'.txt'+' '+fmriprep_script)
