### This script creates launch scripts for manually curating the data into bids
###
### Ellyn Butler
### May 3, 2022 - July 6, 2022

import os
import shutil
import re
import numpy as np
import glob

indir = '/projects/b1108/studies/mwmh/data/raw/neuroimaging/dicoms/'
launchdir = '/projects/b1108/studies/mwmh/data/raw/neuroimaging/launch/bids/'
outdir = '/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/'

subjects = os.listdir(indir)
subjects = [item for item in subjects if 'sub' in item]

for sub in subjects:
    sessions = os.listdir(indir+sub)
    sessions = [item for item in sessions if 'ses' in item]
    for ses in sessions:
        sesdir = outdir+sub+'/'+ses
        if not os.path.isdir(sesdir):
            cmd = ['python3 /projects/b1108/studies/mwmh/scripts/curation/manually_curate.py -s',
                    sub, '-ss', ses]
            curate_script = launchdir+sub+'_'+ses+'_curate_run.sh'
            os.system('cat /projects/b1108/studies/mwmh/scripts/curation/sbatch_info_manually_curate.sh > '+curate_script)
            os.system('echo '+' '.join(cmd)+' >> '+curate_script)
            os.system('chmod +x '+curate_script)
            os.system('sbatch -o '+launchdir+sub+'_'+ses+'.txt'+' '+curate_script)
