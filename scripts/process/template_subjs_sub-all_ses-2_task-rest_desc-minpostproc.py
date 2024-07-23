### This script identifies individuals who have minimally processed 
### resting state data from the second session
### 
### Ellyn Butler
### July 23, 2024

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
    ses2_rest = os.path.exists(indir + sub + '/ses-2/func/' + sub + '_ses-2_task-rest_space-fsLR_desc-minpostproc_bold.dscalar.nii')
    if ses2_rest:
        sesid = 2
        temp_subjs['subid'].append(subid)
        temp_subjs['sesid'].append(sesid)

temp_subjs_df = pd.DataFrame(temp_subjs)
temp_subjs_df.to_csv(outdir + 'temp_subjs_sub-all_ses-2_task-rest_desc-minpostproc.csv', index = False)
