### This script generates submission scripts for fmriprep for the first visit
###
### Ellyn Butler
### November 3, 2022


import os
import shutil
import re
import numpy as np
import glob

outdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/amygconn/'
launchdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/launch/amygconn/'

exclude_path = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/tabulated/exclusions_2022-10-31.csv'
exclude_df = pd.read_csv(exclude_path, sep=',')

subid_sesid = []

for index, row in exclude_df.iterrows():
    subid = row['subid']
    sesid = row['sesid']
    sub = 'sub-'+subid
    ses = 'ses-'+str(sesid)
    if subid+'_'+str(sesid) not in subid_sesid:
        excludes = exclude_df[(exclude_df['subid'] == subid) & (exclude_df['sesid'] == sesid)]['exclude'].to_list()
        # If the rest scan is too short, you can't process it
        if 0 in excludes:
            fname = outdir+'/'+sub+'/'+ses+'/'+sub+'_'+ses+'_atlas-seitz_amygcorr.csv'
            if os.path.isfile(fname):
                os.rename(fname, sesoutdir+'/'+sub+'_'+ses+'_atlas-seitz_amygcorr_old2.csv')
            tasks_list = exclude_df[(exclude_df['subid'] == subid) & (exclude_df['sesid'] == sesid) & (exclude_df['exclude'] == 0)]['task'].to_list()
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
