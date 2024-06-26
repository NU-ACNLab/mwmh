### This script generates submission scripts for fmriprep for the first visit
###
### Ellyn Butler
### June 24, 2024


import os
import shutil
import re
import numpy as np
import glob
import nibabel as nib

indir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep_23.2.0/'
outdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/surf/'
bidsdir = '/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/'
launchdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/launch/surf/'

if not os.path.exists(outdir):
    os.mkdir(outdir)

if not os.path.exists(launchdir):
    os.mkdir(launchdir)

subdirs = glob.glob(indir + "sub-*")

for subdir in subdirs:
    sub = subdir.split('/')[9]
    if not os.path.exists(outdir+sub):
        os.mkdir(outdir+sub)
    sub_bold_imgs = glob.glob(indir+sub+'/*/func/*bold.nii.gz')
    sessions = np.unique([i.split('/')[10] for i in sub_bold_imgs])
    for ses in sessions:
        if not os.path.exists(outdir+sub+'/'+ses):
            os.mkdir(outdir+sub+'/'+ses)
    if len(sub_bold_imgs) > 0:
        cmd = ['bash /projects/b1108/studies/mwmh/scripts/process/create_ciftis_preproc.sh -s', sub]
        create_ciftis_script = launchdir+sub+'_create_ciftis_preproc_run.sh'
        os.system('cat /projects/b1108/studies/mwmh/scripts/process/sbatchinfo_9hr_10G_general.sh > '+create_ciftis_script)
        os.system('echo '+' '.join(cmd)+' >> '+create_ciftis_script)
        os.system('chmod +x '+create_ciftis_script)
        os.system('sbatch -o '+launchdir+sub+'_preproc.txt'+' '+create_ciftis_script)
