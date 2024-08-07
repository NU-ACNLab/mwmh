### This script generates submission scripts for fmriprep for the first visit
###
### Ellyn Butler
### July 2, 2024


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

subdirs = subdirs[0:10]#done
subdirs = subdirs[10:20]#done
subdirs = subdirs[20:30]#done
subdirs = subdirs[30:40]#done
subdirs = subdirs[40:50]#done
subdirs = subdirs[50:60]#done
subdirs = subdirs[60:70]#done
subdirs = subdirs[70:80]#done
subdirs = subdirs[80:90]#done
subdirs = subdirs[90:100]#done
subdirs = subdirs[100:110]#done
subdirs = subdirs[110:120]#done
subdirs = subdirs[120:130]#done
subdirs = subdirs[130:140]#done
subdirs = subdirs[140:150]#done
subdirs = subdirs[150:160]#done
subdirs = subdirs[160:170]#done
subdirs = subdirs[170:180]#done
subdirs = subdirs[180:190]#done
subdirs = subdirs[190:200]#done
subdirs = subdirs[200:210]#done
subdirs = subdirs[210:220]#done
subdirs = subdirs[220:230]#done
subdirs = subdirs[230:240]#done
subdirs = subdirs[240:250]#done
subdirs = subdirs[250:268] 
# run through at the end to redo any subjects without successful output

for subdir in subdirs:
    sub = subdir.split('/')[9]
    subid = sub.split('-')[1]
    ses1_rest = os.path.exists(indir + sub + '/ses-1/func/' + sub + '_ses-1_task-rest_space-fsLR_desc-preproc_bold.dscalar.nii')
    ses1_faces = os.path.exists(indir + sub + '/ses-1/func/' + sub + '_ses-1_task-faces_space-fsLR_desc-preproc_bold.dscalar.nii')
    ses1_avoid = os.path.exists(indir + sub + '/ses-1/func/' + sub + '_ses-1_task-avoid_space-fsLR_desc-preproc_bold.dscalar.nii')
    ses1_outfile = os.path.exists(indir + sub + '/ses-1/func/' + sub + '_ses-1_task-all_space-fsLR_desc-preproc_smoothed.dscalar.nii')
    if (ses1_rest or ses1_faces or ses1_avoid) and not ses1_outfile:
        ses = 'ses-1'
        cmd = ['Rscript /projects/b1108/studies/mwmh/scripts/process/mwall_smooth_preproc.R -s ', subid, ' -e 1']
        mwall_smooth_script = launchdir+sub+'_'+ses+'_mwall_smooth_preproc_run.sh'
        os.system('cat /projects/b1108/studies/mwmh/scripts/process/sbatchinfo_9hr_10G_general.sh > '+mwall_smooth_script)
        os.system('echo '+' '.join(cmd)+' >> '+mwall_smooth_script)
        os.system('chmod +x '+mwall_smooth_script)
        os.system('sbatch -o '+launchdir+sub+'_'+ses+'_mwall_smooth_preproc.txt'+' '+mwall_smooth_script)
    ses2_rest = os.path.exists(indir + sub + '/ses-2/func/' + sub + '_ses-2_task-rest_space-fsLR_desc-preproc_bold.dscalar.nii')
    ses2_faces = os.path.exists(indir + sub + '/ses-2/func/' + sub + '_ses-2_task-faces_space-fsLR_desc-preproc_bold.dscalar.nii')
    ses2_avoid = os.path.exists(indir + sub + '/ses-2/func/' + sub + '_ses-2_task-avoid_space-fsLR_desc-preproc_bold.dscalar.nii')
    ses2_outfile = os.path.exists(indir + sub + '/ses-2/func/' + sub + '_ses-2_task-all_space-fsLR_desc-preproc_smoothed.dscalar.nii')
    if (ses2_rest or ses2_faces or ses2_avoid) and not ses2_outfile:
        ses = 'ses-2'
        cmd = ['Rscript /projects/b1108/studies/mwmh/scripts/process/mwall_smooth_preproc.R -s ', subid, ' -e 2']
        mwall_smooth_script = launchdir+sub+'_'+ses+'_mwall_smooth_preproc_run.sh'
        os.system('cat /projects/b1108/studies/mwmh/scripts/process/sbatchinfo_9hr_10G_general.sh > '+mwall_smooth_script)
        os.system('echo '+' '.join(cmd)+' >> '+mwall_smooth_script)
        os.system('chmod +x '+mwall_smooth_script)
        os.system('sbatch -o '+launchdir+sub+'_'+ses+'_mwall_smooth_preproc.txt'+' '+mwall_smooth_script)

