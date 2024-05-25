### This script identifies individuals who only have one session
### of resting state data so that they can be used in template
### construction, without losing any subjects from the ultimate
### analysis (which requires two session per participant)
### 
### Ellyn Butler
### May 5, 2024

import os
import shutil
import re
import numpy as np
import glob
import pandas as pd

indir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/surf/'
outdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/tabulated/'

subdirs = glob.glob(indir + "sub-*")

temp_subjs = {'subid':[], 'sesid':[]}

for subdir in subdirs:
    sub = subdir.split('/')[9]
    subid = sub.split('-')[1]
    if subid == 'MWMH001':
        continue
    ses1 = os.path.exists(indir + sub + '/ses-1/func/' + sub + '_ses-1_task-rest_space-fsLR_desc-postproc_bold.dscalar.nii')
    ses2 = os.path.exists(indir + sub + '/ses-2/func/' + sub + '_ses-2_task-rest_space-fsLR_desc-postproc_bold.dscalar.nii')
    if ses1 and not ses2:
        sesid = 1
        temp_subjs['subid'].append(subid)
        temp_subjs['sesid'].append(sesid)
    elif not ses1 and ses2:
        sesid = 2
        temp_subjs['subid'].append(subid)
        temp_subjs['sesid'].append(sesid)

temp_subjs_df = pd.DataFrame(temp_subjs)
temp_subjs_df.to_csv(outdir + 'temp_subjs.csv', index = False)
