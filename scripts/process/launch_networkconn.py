### This script generates submission scripts for network connectivity
###
### Ellyn Butler
### June 29, 2023


import os
import shutil
import re
import numpy as np
import glob

indir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/amygconn/'
outdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/networkconn/'
launchdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/launch/networkconn/'

subdirs = glob.glob(indir + "sub-*")

for subdir in subdirs:
    sub = subdir.split('/')[9]
    if not os.path.exists(outdir+sub):
        os.mkdir(outdir+sub)
    sub_bold_imgs = glob.glob(indir+sub+'/*/*/*bold.nii.gz')
    sessions = np.unique([i.split('/')[10] for i in sub_bold_imgs])
    for ses in sessions:
        if not os.path.exists(outdir+sub+'/'+ses):
            os.mkdir(outdir+sub+'/'+ses)
        ses_bold_imgs = glob.glob(indir+sub+'/'+ses+'/*/*bold.nii.gz')
        if len(ses_bold_imgs) > 0:
            tasks_list = np.unique([i.split('/')[12].split('_')[2].split('-')[1] for i in ses_bold_imgs])
            ses_events_files = glob.glob(bidsdir+sub+'/'+ses+'/*/*events.tsv')
            events_list = np.unique([i.split('/')[12].split('_')[2].split('-')[1] for i in ses_events_files])
            # If you don't have an events file, you can't include the task fMRI
            if 'avoid' in tasks_list and 'avoid' not in events_list:
                index = np.argwhere(tasks_list == 'avoid')
                tasks_list = np.delete(tasks_list, index)
            if 'faces' in tasks_list and 'faces' not in events_list:
                index = np.argwhere(tasks_list == 'faces')
                tasks_list = np.delete(tasks_list, index)
            # If the rest scan is too short, you can't process it
            rest_img = nib.load(indir+sub+'/'+ses+'/func/'+sub+'_'+ses+'_task-rest_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz')
            if rest_img.shape[3] < 34:
                index = np.argwhere(tasks_list == 'rest')
                tasks_list = np.delete(tasks_list, index)
            if len(tasks_list) > 0:
                tasks = ' '.join(tasks_list)
                cmd = ['python3 /projects/b1108/studies/mwmh/scripts/process/amygconn.py -i',
                    indir, '-o', outdir, '-b', bidsdir, '-s', sub, '-ss', ses, '-t', tasks]
                amygconn_script = launchdir+sub+'_'+ses+'_amygconn_run.sh'
                os.system('cat /projects/b1108/studies/mwmh/scripts/process/sbatchinfo_40min_general.sh > '+amygconn_script)
                os.system('echo '+' '.join(cmd)+' >> '+amygconn_script)
                os.system('chmod +x '+amygconn_script)
                os.system('sbatch -o '+launchdir+sub+'_'+ses+'.txt'+' '+amygconn_script)
