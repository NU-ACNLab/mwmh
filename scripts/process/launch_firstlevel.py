### This script generates submission scripts for fmriprep for the first visit
###
### Ellyn Butler
### October 31, 2022


import os
import shutil
import re
import numpy as np
import glob

indir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep/'
outdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/firstlevel/'
bidsdir = '/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/'
launchdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/launch/firstlevel/'

subdirs = glob.glob(indir + "sub-*[!.html]")

for subdir in subdirs:
    sub = subdir.split('/')[9]
    sub_bold_imgs = glob.glob(indir+sub+'/*/*/*bold.nii.gz')
    sessions = np.unique([i.split('/')[10] for i in sub_bold_imgs])
    for ses in sessions:
        ses_bold_imgs = glob.glob(indir+sub+'/'+ses+'/*/*bold.nii.gz')
        if len(ses_bold_imgs) > 0:
            tasks_list = np.unique([i.split('/')[12].split('_')[2].split('-')[1] for i in ses_bold_imgs])
            ses_events_files = glob.glob(bidsdir+sub+'/'+ses+'/*/*events.tsv')
            events_list = np.unique([i.split('/')[12].split('_')[2].split('-')[1] for i in ses_events_files])
            # If you don't have an events file, you can't include the task fMRI
            if 'avoid' in tasks_list and 'avoid' in events_list:
                cmd = ['python3 /projects/b1108/studies/mwmh/scripts/process/firstlevel_avoid.py -i',
                    indir, '-o', outdir, '-b', bidsdir, '-s', sub, '-ss', ses]
                avoid_script = launchdir+sub+'_'+ses+'_task-avoid_run.sh'
                os.system('cat /projects/b1108/studies/mwmh/scripts/process/sbatchinfo_firstlevel_general.sh > '+avoid_script)
                os.system('echo '+' '.join(cmd)+' >> '+avoid_script)
                os.system('chmod +x '+avoid_script)
                os.system('sbatch -o '+launchdir+sub+'_'+ses+'_task-avoid.txt'+' '+avoid_script)
            if 'faces' in tasks_list and 'faces' in events_list:
                cmd = ['python3 /projects/b1108/studies/mwmh/scripts/process/firstlevel_faces.py -i',
                    indir, '-o', outdir, '-b', bidsdir, '-s', sub, '-ss', ses]
                faces_script = launchdir+sub+'_'+ses+'_task-faces_run.sh'
                os.system('cat /projects/b1108/studies/mwmh/scripts/process/sbatchinfo_firstlevel_general.sh > '+faces_script)
                os.system('echo '+' '.join(cmd)+' >> '+faces_script)
                os.system('chmod +x '+faces_script)
                os.system('sbatch -o '+launchdir+sub+'_'+ses+'_task-faces.txt'+' '+faces_script)
