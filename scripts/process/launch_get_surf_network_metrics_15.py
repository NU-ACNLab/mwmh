### This script generates submission obtaining personalized network metrics
###
### Ellyn Butler
### March 31, 2025 - April 2, 2025

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
        sesid = ses.split('-')[1]
        if not os.path.exists(outdir+sub+'/'+ses):
            os.mkdir(outdir+sub+'/'+ses)
        if not os.path.exists(outdir + 'sub-' + subid + '/ses-' + sesid + '/sub-' +
                              subid + '_ses-' + sesid + '_surf_network_metrics_15.csv'):
            sesid = str(ses).split('-')[1]
            cmd = ['Rscript /projects/b1108/studies/mwmh/scripts/process/get_surf_network_metrics_15.R -s', subid, '-e', sesid]
            get_surf_network_metrics_script = launchdir+sub+'_'+ses+'_get_surf_network_metrics_run_15.sh'
            os.system('cat /projects/b1108/studies/mwmh/scripts/process/sbatchinfo_9hr_10G_general.sh > '+get_surf_network_metrics_script)
            os.system('echo module purge >> '+get_surf_network_metrics_script)
            os.system('echo module load gdal/3.1.3-R-4.1.1 proj/7.1.1 geos/3.8.1 gsl/2.6-gcc-8.4.0 >> '+get_surf_network_metrics_script)
            os.system('echo module load R/4.3.0 >> '+get_surf_network_metrics_script)
            os.system('echo module load udunits2/2.2.20 >> '+get_surf_network_metrics_script)
            os.system('echo '+' '.join(cmd)+' >> '+get_surf_network_metrics_script)
            os.system('chmod +x '+get_surf_network_metrics_script)
            os.system('sbatch -o '+launchdir+sub+'_'+ses+'_get_surf_network_metrics_15.txt'+' '+get_surf_network_metrics_script)
