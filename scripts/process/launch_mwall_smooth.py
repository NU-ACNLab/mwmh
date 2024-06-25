### This script generates submission scripts for fmriprep for the first visit
###
### Ellyn Butler
### June 25, 2024


import os
import shutil
import re
import numpy as np
import glob
import nibabel as nib
import pandas as pd

indir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/surf/'
outdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/surf/'
bidsdir = '/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/'
launchdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/launch/surf/'
tabdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/tabulated/'

if not os.path.exists(outdir):
    os.mkdir(outdir)

if not os.path.exists(launchdir):
    os.mkdir(launchdir)

subdirs = glob.glob(indir + "sub-*")

for subdir in subdirs:
    sub = subdir.split('/')[9]
    ses = 
    ses2_rest = os.path.exists(indir + sub + '/ses-2/func/' + sub + '_ses-2_task-rest_space-fsLR_desc-postproc_bold.dscalar.nii')
    ses2_faces = os.path.exists(indir + sub + '/ses-2/func/' + sub + '_ses-2_task-faces_space-fsLR_desc-postproc_bold.dscalar.nii')
    ses2_avoid = os.path.exists(indir + sub + '/ses-2/func/' + sub + '_ses-2_task-avoid_space-fsLR_desc-postproc_bold.dscalar.nii')
    if ses2_rest or ses2_faces or ses2_avoid:
        cmd = ['bash /projects/b1108/studies/mwmh/scripts/process/mwall_smooth.R -s', sub, ' -e', ses]
        mwall_smooth_script = launchdir+sub+'_mwall_smooth_run.sh'
        os.system('cat /projects/b1108/studies/mwmh/scripts/process/sbatchinfo_9hr_10G_general.sh > '+mwall_smooth_script)
        os.system('echo '+' '.join(cmd)+' >> '+mwall_smooth_script)
        os.system('chmod +x '+mwall_smooth_script)
        os.system('sbatch -o '+launchdir+sub+'_mwall_smooth.txt'+' '+mwall_smooth_script)
