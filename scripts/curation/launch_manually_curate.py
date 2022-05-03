### This script creates launch scripts for manually curating the data into bids
###
### Ellyn Butler
### May 3, 2022

import os
import shutil
import re
import numpy as np
import glob

indir = '/projects/b1108/studies/mwmh/data/raw/neuroimaging/dicoms'
outdir = '/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids'
launchdir = '/projects/b1108/studies/mwmh/data/raw/neuroimaging/launch/bids/'

subjects = os.listdir(indir)
subjects = [item for item in subjects if 'sub' in item]

#sub = 'sub-MWMH179'
for sub in subjects:
    sessions = os.listdir(indir+'/'+sub)
    sessions = [item for item in sessions if 'ses' in item]
    for ses in sessions:
        scans = os.listdir(indir+'/'+sub+'/'+ses+'/SCANS/')
        scans = [item for item in scans if 'DICOM' in os.listdir(indir+'/'+sub+'/'+ses+'/SCANS/'+item)]
        for scan in scans:
            cmd = []
            curate_script = launchdir+subj+'_'+ses+'_curate_run.sh'
            os.system('cat /home/erb9722/studies/mwmh/scripts/process/sbatch_info_manually_curate.sh > '+fmriprep_script)
            os.system('echo '+' '.join(cmd)+' >> '+fmriprep_script)
            os.system('chmod +x '+fmriprep_script)
            os.system('sbatch -o /projects/b1108/data/MWMH/launch/fmriprep/'+subj+'_'+ses+'.txt'+' '+fmriprep_script)



sbatch_info_manually_curate.sh

for subDir in subDirs:
    subj = subDir.split('/')[6]
    if not os.path.exists(outdir+subj):
        os.mkdir(outdir+subj)
    unprocessed_sessions = np.setdiff1d(os.listdir(indir+subj), os.listdir(outdir+subj))
    for ses in unprocessed_sessions:
        if not os.path.exists(outdir+subj+'/'+ses):
            os.mkdir(outdir+subj+'/'+ses)
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
        os.system('cat /home/erb9722/studies/mwmh/scripts/process/sbatchinfo.sh > '+fmriprep_script)
        os.system('echo '+' '.join(cmd)+' >> '+fmriprep_script)
        os.system('chmod +x '+fmriprep_script)
        os.system('sbatch -o /projects/b1108/data/MWMH/launch/fmriprep/'+subj+'_'+ses+'.txt'+' '+fmriprep_script)
