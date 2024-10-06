### This script identifies individuals who only have one session
### of resting state data so that they can be used in template
### construction, without losing any subjects from the ultimate
### analysis (which requires two session per participant)
### 
### Ellyn Butler
### May 25, 2024

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
    ses1_rest = os.path.exists(indir + sub + '/ses-1/func/' + sub + '_ses-1_task-rest_space-fsLR_desc-postproc_bold.dscalar.nii')
    ses2_rest = os.path.exists(indir + sub + '/ses-2/func/' + sub + '_ses-2_task-rest_space-fsLR_desc-postproc_bold.dscalar.nii')
    ses1_faces = os.path.exists(indir + sub + '/ses-1/func/' + sub + '_ses-1_task-faces_space-fsLR_desc-postproc_bold.dscalar.nii')
    ses2_faces = os.path.exists(indir + sub + '/ses-2/func/' + sub + '_ses-2_task-faces_space-fsLR_desc-postproc_bold.dscalar.nii')
    ses1_avoid = os.path.exists(indir + sub + '/ses-1/func/' + sub + '_ses-1_task-avoid_space-fsLR_desc-postproc_bold.dscalar.nii')
    ses2_avoid = os.path.exists(indir + sub + '/ses-2/func/' + sub + '_ses-2_task-avoid_space-fsLR_desc-postproc_bold.dscalar.nii')
    if (ses1_rest or ses1_faces or ses1_avoid) and not (ses2_rest or ses2_faces or ses2_avoid):
        sesid = 1
        temp_subjs['subid'].append(subid)
        temp_subjs['sesid'].append(sesid)
    elif (ses2_rest or ses2_faces or ses2_avoid) and not (ses1_rest or ses1_faces or ses1_avoid):
        sesid = 2
        temp_subjs['subid'].append(subid)
        temp_subjs['sesid'].append(sesid)

temp_subjs_df = pd.DataFrame(temp_subjs)
temp_subjs_df.to_csv(outdir + 'temp_subjs_task-all.csv', index = False)
