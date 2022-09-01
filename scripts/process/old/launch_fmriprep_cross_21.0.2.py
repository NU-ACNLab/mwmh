### This script generates submission scripts for fmriprep separately for each
### session.
###
### Ellyn Butler
### August 15, 2022

# PROBLEM: As is, html files will get overwritten. This might not be worth it.

import os
import shutil
import re
import numpy as np
import glob

indir = '/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/'
outdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep/'
launchdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/launch/fmriprep/'

subdirs = glob.glob(indir + "sub-*")
# subdirs = [subdirs[36]]
# subdirs = ['/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/sub-MWMH221',
#            '/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/sub-MWMH001']
#subdirs = ['/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/sub-MWMH169']

for subdir in subdirs:
    sub = subdir.split('/')[9]
    if not os.path.exists(outdir+sub):
        os.mkdir(outdir+sub)
    #unprocessed_sessions = np.setdiff1d(os.listdir(indir+sub), os.listdir(outdir+sub))
    sessions = os.listdir(indir+sub)
    for ses in sessions:
        if not os.path.exists(outdir+sub+'/'+ses):
            os.mkdir(outdir+sub+'/'+ses)
        if ses == 'ses-1':
            participant_label = sub.split('-')[1]
            cmd = ['SINGULARITYENV_TEMPLATEFLOW_HOME=/home/fmriprep/.cache/templateflow',
                'singularity', 'run', '--writable-tmpfs', '--cleanenv', '--containall',
                '-B /tmp:/tmp', '-B /projects/b1108:/projects/b1108',
                '-B /projects/b1108/software/freesurfer_license/license.txt:/opt/freesurfer/license.txt',
                '-B /projects/b1108/templateflow:/home/fmriprep/.cache/templateflow',
                '/projects/b1108/software/singularity_images/fmriprep_21.0.2.sif',
                indir, outdir, 'participant', '--participant-label',
                participant_label, '--nprocs=1 --omp-nthreads=1',
                '-w /projects/b1108/studies/mwmh/data/processed/neuroimaging/work1',
                '--fs-license-file /opt/freesurfer/license.txt',
                '--output-spaces MNI152NLin6Asym', '--skull-strip-template OASIS30ANTs',
                '--bids-filter-file', '/projects/b1108/data/MWMH/config/'+ses+'_config.json']
            fmriprep_script = launchdir+sub+'_'+ses+'_fmriprep_run.sh'
            os.system('cat /projects/b1108/studies/mwmh/scripts/process/sbatchinfo_general_long.sh > '+fmriprep_script) #_long
            os.system('echo '+' '.join(cmd)+' >> '+fmriprep_script)
            os.system('chmod +x '+fmriprep_script)
            os.system('sbatch -o '+launchdir+sub+'_'+ses+'.txt'+' '+fmriprep_script)
        else:
            if not os.path.exists(outdir+sub+'/'+ses):
                os.mkdir(outdir+sub+'/'+ses)
            participant_label = sub.split('-')[1]
            cmd = ['SINGULARITYENV_TEMPLATEFLOW_HOME=/home/fmriprep/.cache/templateflow',
                'singularity', 'run', '--writable-tmpfs', '--cleanenv', '--containall',
                '-B /tmp:/tmp', '-B /projects/b1108:/projects/b1108',
                '-B /projects/b1108/software/freesurfer_license/license.txt:/opt/freesurfer/license.txt',
                '-B /projects/b1108/templateflow:/home/fmriprep/.cache/templateflow',
                '/projects/b1108/software/singularity_images/fmriprep_21.0.2.sif',
                indir, outdir, 'participant', '--participant-label', participant_label,
                '--nprocs=1 --omp-nthreads=1',
                '-w /projects/b1108/studies/mwmh/data/processed/neuroimaging/work2',
                '--fs-license-file /opt/freesurfer/license.txt',
                '--output-spaces MNI152NLin6Asym', '--skull-strip-template OASIS30ANTs',
                '--bids-filter-file', '/projects/b1108/data/MWMH/config/'+ses+'_config.json']
            fmriprep_script = launchdir+sub+'_'+ses+'_fmriprep_run.sh'
            os.system('cat /projects/b1108/studies/mwmh/scripts/process/sbatchinfo_general_long.sh > '+fmriprep_script)
            os.system('echo '+' '.join(cmd)+' >> '+fmriprep_script)
            os.system('chmod +x '+fmriprep_script)
            os.system('sbatch -o '+launchdir+sub+'_'+ses+'.txt'+' '+fmriprep_script)
