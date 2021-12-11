### This script resubmits ses-1 jobs with no output to the general Quest nodes
###
### Ellyn Butler
### December 11, 2021


import os
import shutil
import re
import numpy as np
import glob

indir = '/projects/b1108/data/MWMH/bids_directory/'
outdir = '/projects/b1108/data/MWMH/fmriprep/'
launchdir = '/projects/b1108/data/MWMH/launch/fmriprep/'

subDirs = glob.glob(indir + "sub-*")

for subDir in subDirs:
    subj = subDir.split('/')[6]
    if not os.path.exists(outdir+subj):
        os.mkdir(outdir+subj)
    sessions = os.listdir(indir+subj)
    if 'ses-1' in sessions:
        ses = 'ses-1'
        if not os.path.exists(outdir+subj+'/'+ses):
            os.mkdir(outdir+subj+'/'+ses)
        ses_indir = indir+subj+'/'+ses
        ses_outdir = outdir+subj+'/'+ses
        participant_label = subj.split('-')[1]
        cmd = ['SINGULARITYENV_TEMPLATEFLOW_HOME=/home/fmriprep/.cache/templateflow',
            'singularity', 'run', '--writable-tmpfs', '--cleanenv', '--containall',
            '-B /projects/b1108:/projects/b1108',
            '-B /projects/b1108/software/freesurfer_license/license.txt:/opt/freesurfer/license.txt',
            '-B /projects/b1108/templateflow:/home/fmriprep/.cache/templateflow',
            '/home/erb9722/fmriprep_20.2.3.sif', '/projects/b1108/data/MWMH/bids_directory',
            '/projects/b1108/data/MWMH', 'participant', '--participant-label',
            participant_label, '--fs-no-reconall',
            '-w /projects/b1108/data/MWMH/work',
            '--fs-license-file /opt/freesurfer/license.txt',
            '--output-spaces MNI152NLin6Asym', '--skull-strip-template OASIS30ANTs',
            '--bids-filter-file', '/projects/b1108/data/MWMH/config/'+ses+'_config.json']
        fmriprep_script = launchdir+subj+'_'+ses+'_fmriprep_run.sh'
        os.system('cat /home/erb9722/studies/mwmh/scripts/process/sbatchinfo_general.sh > '+fmriprep_script)
        os.system('echo '+' '.join(cmd)+' >> '+fmriprep_script)
        os.system('chmod +x '+fmriprep_script)
        os.system('sbatch -o /projects/b1108/data/MWMH/launch/fmriprep/'+subj+'_'+ses+'_general.txt'+' '+fmriprep_script)
