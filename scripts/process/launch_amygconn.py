### This script generates submission scripts for fmriprep for the first visit
###
### Ellyn Butler
### December 12, 2021


import os
import shutil
import re
import numpy as np
import glob

indir = '/projects/b1108/data/MWMH/fmriprep/'
outdir = '/projects/b1108/data/MWMH/amygconn/'
launchdir = '/projects/b1108/data/MWMH/launch/amygconn/'

subDirs = glob.glob(indir + "sub-*[!.html]")

for subDir in subDirs:
    sub = subDir.split('/')[6]
    if not os.path.exists(outdir+sub):
        os.mkdir(outdir+sub)
    bold_imgs = glob.glob(indir+sub+'/*/*/*bold.nii.gz')
    if len(bold_imgs) > 0:
        sessions = [i.split('/')[7] for i in bold_imgs]
        for ses in sessions:
            if not os.path.exists(outdir+sub+'/'+ses):
                os.mkdir(outdir+sub+'/'+ses)
            cmd = ['python3 /home/erb9722/studies/mwmh/scripts/process/amygconn.py -i',
                indir, '-o', outdir, '-s', sub, '-ss', ses]
            amygconn_script = launchdir+sub+'_'+ses+'_amygconn_run.sh'
            os.system('cat /home/erb9722/studies/mwmh/scripts/process/sbatchinfo_10min_general.sh > '+amygconn_script)
            os.system('echo '+' '.join(cmd)+' >> '+amygconn_script)
            os.system('chmod +x '+amygconn_script)
            os.system('sbatch -o /projects/b1108/data/MWMH/launch/amygconn/'+sub+'_'+ses+'.txt'+' '+amygconn_script)
