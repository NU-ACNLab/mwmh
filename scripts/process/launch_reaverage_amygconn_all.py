### This script generates submission scripts for fmriprep for the first visit
###
### Ellyn Butler
### December 12, 2021 - October 25, 2022


import os
import shutil
import re
import numpy as np
import glob

indir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep/'
outdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/amygconn/'
bidsdir = '/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/'
launchdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/launch/amygconn/'

exclude_path = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/tabulated/exclusions_2022-10-31.csv'
exclude_df = pd.read_csv(exclude_path, sep=',')

subid_sesid = []

for index, row in exclude_df.iterrows():
    subid = row['subid']
    sesid = row['sesid']
    sub = 'sub-'+subid
    ses = 'ses-'+str(sesid)
    ses_bold_imgs = glob.glob(indir+sub+'/'+ses+'/*/*bold.nii.gz')
    if subid+'_'+str(sesid) not in subid_sesid:
        excludes = exclude_df[(exclude_df['subid'] == subid) & (exclude_df['sesid'] == sesid)]['exclude'].to_list()
        tasks_list = exclude_df[(exclude_df['subid'] == subid) & (exclude_df['sesid'] == sesid) & (exclude_df['exclude'] == 0)]['task'].to_list()
        # If the rest scan is too short, you can't process it
        if 0 in excludes:
            os.rename(sesoutdir+'/'+sub+'_'+ses+'_atlas-seitz_amygcorr.csv', sesoutdir+'/'+sub+'_'+ses+'_atlas-seitz_amygcorr_old2.csv')
            tasks_list = exclude_df[(exclude_df['subid'] == subid) & (exclude_df['sesid'] == sesid) & (exclude_df['exclude'] == 0)]['task'].to_list()
            rest_img = nib.load(indir+sub+'/'+ses+'/func/'+sub+'_'+ses+'_task-rest_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz')
            if rest_img.shape[3] < 34:
                i = np.argwhere(tasks_list == 'rest')
                tasks_list = np.delete(tasks_list, i)
            tasks = ' '.join(tasks_list)
            cmd = ['python3 /projects/b1108/studies/mwmh/scripts/process/reaverage_amygconn.py -o',
                outdir, '-s', sub, '-ss', ses, '-t', tasks]
            amygconn_script = launchdir+sub+'_'+ses+'_reaverage_amygconn_all_run.sh'
            os.system('cat /projects/b1108/studies/mwmh/scripts/process/sbatchinfo_10min_general.sh > '+amygconn_script)
            os.system('echo '+' '.join(cmd)+' >> '+amygconn_script)
            os.system('chmod +x '+amygconn_script)
            os.system('sbatch -o '+launchdir+sub+'_'+ses+'_reaverage_all.txt'+' '+amygconn_script)
            subid_sesid.append(subid+'_'+str(sesid))
        else:
            fname = outdir+'/'+sub+'/'+ses+'/'+sub+'_'+ses+'_atlas-seitz_amygcorr.csv'
            if os.path.isfile(fname):
                os.rename(fname, outdir+'/'+sub+'/'+ses+'/'+sub+'_'+ses+'_atlas-seitz_amygcorr_old2.csv')
            subid_sesid.append(subid+'_'+str(sesid))
