### Find the five subjects who keep failing from the first 50.
###
### Ellyn Butler
### September 4, 2022



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
subdirs = subdirs[0:50]

for subdir in subdirs:
    sub = subdir.split('/')[9]
    txtlog = launchdir+sub+'.txt'
    if os.path.exists(txtlog):
        print(sub)
        os.system('grep -i "error"'+txtlog)
        #shutil.rmtree(workdir+'fmriprep_wf/single_subject_'+participant_label+'_wf')
