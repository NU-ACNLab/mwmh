### This script generates submission scripts for fmriprep for the first visit
###
### Ellyn Butler
### August 20, 2024


import os
import shutil
import re
import numpy as np
import glob
import nibabel as nib
import pandas as pd

indir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/surf/'
outdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/surf/'
launchdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/launch/surf/'

if not os.path.exists(outdir):
    os.mkdir(outdir)

if not os.path.exists(launchdir):
    os.mkdir(launchdir)

subdirs = glob.glob(indir + "sub-*")


for subdir in subdirs:
    sub = subdir.split('/')[9]
    subid = sub.split('-')[1]
    ses1_rest = os.path.exists(indir + sub + '/ses-1/func/' + sub + '_ses-1_task-rest_space-fsLR_desc-medpostproc_bold.dscalar.nii')
    ses1_outfile = os.path.exists(indir + sub + '/ses-1/func/' + sub + '_ses-1_task-rest_space-fsLR_desc-medpostproc_meanmed.dscalar.nii')
    if ses1_rest and not ses1_outfile:
        ses = 'ses-1'
        cmd = ['Rscript /projects/b1108/studies/mwmh/scripts/process/bad_vertices.R -s ', subid, ' -e 1']
        bad_vertices_script = launchdir+sub+'_'+ses+'_bad_vertices_run.sh'
        os.system('cat /projects/b1108/studies/mwmh/scripts/process/sbatchinfo_20min_10G_general.sh > '+bad_vertices_script)
        os.system('echo '+' '.join(cmd)+' >> '+bad_vertices_script)
        os.system('chmod +x '+bad_vertices_script)
        os.system('sbatch -o '+launchdir+sub+'_'+ses+'_bad_vertices.txt'+' '+bad_vertices_script)
    ses2_rest = os.path.exists(indir + sub + '/ses-2/func/' + sub + '_ses-2_task-rest_space-fsLR_desc-medpostproc_bold.dscalar.nii')
    ses2_outfile = os.path.exists(indir + sub + '/ses-2/func/' + sub + '_ses-2_task-rest_space-fsLR_desc-medpostproc_meanmed.dscalar.nii')
    if ses2_rest and not ses2_outfile:
        ses = 'ses-2'
        cmd = ['Rscript /projects/b1108/studies/mwmh/scripts/process/bad_vertices.R -s ', subid, ' -e 2']
        bad_vertices_script = launchdir+sub+'_'+ses+'_bad_vertices_run.sh'
        os.system('cat /projects/b1108/studies/mwmh/scripts/process/sbatchinfo_20min_10G_general.sh > '+bad_vertices_script)
        os.system('echo '+' '.join(cmd)+' >> '+bad_vertices_script)
        os.system('chmod +x '+bad_vertices_script)
        os.system('sbatch -o '+launchdir+sub+'_'+ses+'_bad_vertices.txt'+' '+bad_vertices_script)

