### This script generates submission scripts for network connectivity
###
### Ellyn Butler
### June 29, 2023


import os
import shutil
import re
import numpy as np
import glob

indir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/amygconn/'
outdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/networkconn/'
launchdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/launch/networkconn/'

subdirs = glob.glob(indir + "sub-*")

for subdir in subdirs:
    sub = subdir.split('/')[9]
    if not os.path.exists(outdir+sub):
        os.mkdir(outdir+sub)
    amygcorrs = glob.glob(indir+sub+'/*/*_amygcorr.csv')
    sessions = np.unique([i.split('/')[10] for i in amygcorrs])
    for ses in sessions:
        if not os.path.exists(outdir+sub+'/'+ses):
            os.mkdir(outdir+sub+'/'+ses)
        ses_corrmats = glob.glob(indir+sub+'/'+ses+'/*_corrmat.csv')
        if len(ses_corrmats) > 0:
            cmd = ['python3 /projects/b1108/studies/mwmh/scripts/process/networkconn.py -i',
                    indir, '-o', outdir, '-s', sub, '-ss', ses]
            networkconn_script = launchdir+sub+'_'+ses+'_networkconn_run.sh'
            os.system('cat /projects/b1108/studies/mwmh/scripts/process/sbatchinfo_40min_general.sh > '+networkconn_script)
            os.system('echo '+' '.join(cmd)+' >> '+networkconn_script)
            os.system('chmod +x '+networkconn_script)
            os.system('sbatch -o '+launchdir+sub+'_'+ses+'.txt'+' '+networkconn_script)
