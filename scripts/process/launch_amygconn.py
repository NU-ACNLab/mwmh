### This script generates submission scripts for fmriprep for the first visit
###
### Ellyn Butler
### December 12, 2021 - October 20, 2022


import os
import shutil
import re
import numpy as np
import glob

indir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep/'
outdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/amygconn/'
bidsdir = '/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/'
launchdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/launch/amygconn/'

subdirs = glob.glob(indir + "sub-*[!.html]")

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
            tasks = ' '.join(tasks_list)
            cmd = ['python3 /projects/b1108/studies/mwmh/scripts/process/amygconn.py -i',
                indir, '-o', outdir, '-b', bidsdir, '-s', sub, '-ss', ses, '-t', tasks]
            amygconn_script = launchdir+sub+'_'+ses+'_amygconn_run.sh'
            os.system('cat /projects/b1108/studies/mwmh/scripts/process/sbatchinfo_40min_general.sh > '+amygconn_script)
            os.system('echo '+' '.join(cmd)+' >> '+amygconn_script)
            os.system('chmod +x '+amygconn_script)
            os.system('sbatch -o '+launchdir+sub+'_'+ses+'.txt'+' '+amygconn_script)
