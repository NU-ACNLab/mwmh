### This script generates submission obtaining personalized network metrics
###
### Ellyn Butler
### August 6, 2024

import os
import shutil
import re
import numpy as np
import glob
import nibabel as nib

launchdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/launch/surfnet/'
indir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/surf/'
outdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/surfnet/'

if not os.path.exists(launchdir):
    os.mkdir(launchdir)

subdirs = glob.glob(indir + "sub-*")

for subdir in subdirs:
    sub = subdir.split('/')[9]
    if not os.path.exists(outdir+sub):
        os.mkdir(outdir+sub)
    sub_bold_imgs = glob.glob(indir+sub+'/*/*/*_task-rest_space-fsLR_desc-maxpostproc_bold.dscalar.nii')
    sessions = np.unique([i.split('/')[10] for i in sub_bold_imgs])
    subid = sub.split('-')[1]
    for ses in sessions:
        if not os.path.exists(outdir+sub+'/'+ses):
            os.mkdir(outdir+sub+'/'+ses)
        sesid = str(ses).split('-')[1]
        cmd = ['Rscript /projects/b1108/studies/mwmh/scripts/process/get_expansiveness.R -s', subid, '-e', sesid]
        get_expansiveness_script = launchdir+sub+'_'+ses+'_get_expansiveness_run.sh'
        os.system('cat /projects/b1108/studies/mwmh/scripts/process/sbatchinfo_9hr_10G_general.sh > '+get_expansiveness_script)
        os.system('echo '+' '.join(cmd)+' >> '+get_expansiveness_script)
        os.system('chmod +x '+get_expansiveness_script)
        os.system('sbatch -o '+launchdir+sub+'_'+ses+'_get_expansiveness.txt'+' '+get_expansiveness_script)
