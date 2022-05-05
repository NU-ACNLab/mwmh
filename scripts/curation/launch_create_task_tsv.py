### This script creates launch scripts for each of the sessions to produce
### events tsv files
###
### Ellyn Butler
### May 5, 2022


import os
import shutil
import re
import numpy as np
import glob

indir = '/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/'
launchdir = '/projects/b1108/studies/mwmh/data/raw/neuroimaging/launch/tsv/'

subjects = os.listdir(indir)
subjects = [item for item in subjects if 'sub' in item]

for sub in subjects:
    sessions = os.listdir(indir+sub)
    sessions = [item for item in sessions if 'ses' in item]
    for ses in sessions:
        mods = os.listdir(indir+sub+'/'+ses)
        if 'func' in mods:
            sublab = sub.split('-')[1]
            seslab = ses.split('-')[1]
            cmd = ['Rscript /projects/b1108/studies/mwmh/scripts/curation/create_task_tsv.R', sublab, seslab]
            tsv_script = launchdir+sub+'_'+ses+'_tsv_run.sh'
            os.system('cat /projects/b1108/studies/mwmh/scripts/curation/sbatch_info_manually_curate.sh > '+tsv_script)
            os.system('echo '+' '.join(cmd)+' >> '+tsv_script)
            os.system('chmod +x '+tsv_script)
            os.system('sbatch -o '+launchdir+sub+'_'+ses+'.txt'+' '+tsv_script)
