### This script generates submission scripts for fmriprep for the first visit
###
### Ellyn Butler
### May 5, 2022 - September 4, 2022


import os
import shutil
import re
import numpy as np
import glob

indir = '/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/'
outdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep/'
launchdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/launch/fmriprep/'
workdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/work2/'

subdirs = glob.glob(indir + "sub-*")
# 1 - launched September 1, 2022, finished September 3, 2022
#subdirs = subdirs[0:50]
# 2 - launched September 3, 2022, finished September 8, 2022
#subdirs = subdirs[0:100]

# subdirs = [subdirs[36]]
# subdirs = ['/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/sub-MWMH221',
#            '/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/sub-MWMH001']


for subdir in subdirs:
    sub = subdir.split('/')[9]
    if not os.path.exists(outdir+sub):
        os.mkdir(outdir+sub)
    participant_label = sub.split('-')[1]
    # Check if the subject has already finished processing (couldn't have if they don't have an html)
    if not os.path.exists(outdir+sub+'.html'):
        sessions = os.listdir(indir+sub)
        txtlog = launchdir+sub+'.txt'
        # If there are any errors in the log file, delete the working directory
        # and the output directory
        with open(txtlog) as myfile:
            if 'ERROR' in myfile.read():
                subworkdir = workdir+'fmriprep_wf/single_subject_'+participant_label+'_wf'
                if os.path.exists(subworkdir):
                    shutil.rmtree(subworkdir)
                shutil.rmtree(outdir+sub)
                os.mkdir(outdir+sub)
        # run!
        if len(sessions) > 1:
            for ses in sessions:
                if not os.path.exists(outdir+sub+'/'+ses):
                    os.mkdir(outdir+sub+'/'+ses)
            cmd = ['SINGULARITYENV_TEMPLATEFLOW_HOME=/home/fmriprep/.cache/templateflow',
                'singularity', 'run', '--writable-tmpfs', '--cleanenv', '--containall',
                '-B /tmp:/tmp', '-B /projects/b1108:/projects/b1108',
                '-B /projects/b1108/software/freesurfer_license/license.txt:/opt/freesurfer/license.txt',
                '-B /projects/b1108/templateflow:/home/fmriprep/.cache/templateflow',
                '/projects/b1108/software/singularity_images/fmriprep_21.0.2.sif',
                indir, outdir, 'participant', '--participant-label',
                participant_label, '--longitudinal', '--nprocs=1 --omp-nthreads=1',
                '-w ', workdir,
                '--fs-license-file /opt/freesurfer/license.txt',
                '--output-spaces MNI152NLin6Asym', '--skull-strip-template OASIS30ANTs']
            fmriprep_script = launchdir+sub+'_fmriprep_run.sh'
            os.system('cat /projects/b1108/studies/mwmh/scripts/process/sbatchinfo_general_extralong.sh > '+fmriprep_script) #_long
            os.system('echo '+' '.join(cmd)+' >> '+fmriprep_script)
            os.system('chmod +x '+fmriprep_script)
            os.system('sbatch -o '+launchdir+sub+'.txt'+' '+fmriprep_script)
        else:
            ses = sessions[0]
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
                '-w ', workdir,
                '--fs-license-file /opt/freesurfer/license.txt',
                '--output-spaces MNI152NLin6Asym', '--skull-strip-template OASIS30ANTs']
            fmriprep_script = launchdir+sub+'_fmriprep_run.sh'
            os.system('cat /projects/b1108/studies/mwmh/scripts/process/sbatchinfo_general_extralong.sh > '+fmriprep_script)
            os.system('echo '+' '.join(cmd)+' >> '+fmriprep_script)
            os.system('chmod +x '+fmriprep_script)
            os.system('sbatch -o '+launchdir+sub+'.txt'+' '+fmriprep_script)
    # if the subject does have an html...
    else:
        # delete working directory
        participant_label = sub.split('-')[1]
        subworkdir = workdir+'fmriprep_wf/single_subject_'+participant_label+'_wf'
        if os.path.exists(subworkdir):
            shutil.rmtree(subworkdir)
        # but if there are errors in the log file, delete old output and rerun
        txtlog = launchdir+sub+'.txt'
        with open(txtlog) as myfile:
            if 'ERROR' in myfile.read():
                # delete faulty output
                shutil.rmtree(outdir+sub)
                os.mkdir(outdir+sub)
                # delete old log
                os.remove(txtlog)
                sessions = os.listdir(indir+sub)
                if len(sessions) > 1:
                    for ses in sessions:
                        if not os.path.exists(outdir+sub+'/'+ses):
                            os.mkdir(outdir+sub+'/'+ses)
                    cmd = ['SINGULARITYENV_TEMPLATEFLOW_HOME=/home/fmriprep/.cache/templateflow',
                        'singularity', 'run', '--writable-tmpfs', '--cleanenv', '--containall',
                        '-B /tmp:/tmp', '-B /projects/b1108:/projects/b1108',
                        '-B /projects/b1108/software/freesurfer_license/license.txt:/opt/freesurfer/license.txt',
                        '-B /projects/b1108/templateflow:/home/fmriprep/.cache/templateflow',
                        '/projects/b1108/software/singularity_images/fmriprep_21.0.2.sif',
                        indir, outdir, 'participant', '--participant-label',
                        participant_label, '--longitudinal', '--nprocs=1 --omp-nthreads=1',
                        '-w ', workdir,
                        '--fs-license-file /opt/freesurfer/license.txt',
                        '--output-spaces MNI152NLin6Asym', '--skull-strip-template OASIS30ANTs']
                    fmriprep_script = launchdir+sub+'_fmriprep_run.sh'
                    os.system('cat /projects/b1108/studies/mwmh/scripts/process/sbatchinfo_general_extralong.sh > '+fmriprep_script) #_long
                    os.system('echo '+' '.join(cmd)+' >> '+fmriprep_script)
                    os.system('chmod +x '+fmriprep_script)
                    os.system('sbatch -o '+launchdir+sub+'.txt'+' '+fmriprep_script)
                else:
                    ses = sessions[0]
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
                        '-w ', workdir,
                        '--fs-license-file /opt/freesurfer/license.txt',
                        '--output-spaces MNI152NLin6Asym', '--skull-strip-template OASIS30ANTs']
                    fmriprep_script = launchdir+sub+'_fmriprep_run.sh'
                    os.system('cat /projects/b1108/studies/mwmh/scripts/process/sbatchinfo_general_extralong.sh > '+fmriprep_script)
                    os.system('echo '+' '.join(cmd)+' >> '+fmriprep_script)
                    os.system('chmod +x '+fmriprep_script)
                    os.system('sbatch -o '+launchdir+sub+'.txt'+' '+fmriprep_script)
