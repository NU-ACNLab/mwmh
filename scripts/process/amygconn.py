### This script conducts the post-processing steps after fmriprep
###
### Ellyn Butler
### November 22, 2021 - December 12, 2021

import os
import json
import pandas as pd
import nibabel as nib
import numpy as np
#from bids.layout import BIDSLayout #may not be needed
from nilearn.input_data import NiftiLabelsMasker
from nilearn.connectome import ConnectivityMeasure
from nilearn import plotting
import sys, getopt
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('-i', default='/projects/b1108/data/MWMH/fmriprep/')
parser.add_argument('-o', default='/projects/b1108/data/MWMH/amygconn/')
parser.add_argument('-s')
parser.add_argument('-ss')
args = parser.parse_args()

inDir = args.i
outDir = args.o
sub = args.s
ses = args.ss

# directory where preprocessed fMRI data is located
subInDir = os.path.join(inDir, sub)
sesInDir = os.path.join(subInDir, ses)
funcInDir = os.path.join(sesInDir, 'func')

# location of the pre-processed fMRI & mask
fList = os.listdir(funcInDir)
imagefMRI = [x for x in fList if ('preproc_bold.nii.gz' in x)][0]
imageMask = [x for x in fList if ('brain_mask.nii.gz' in x)][0]

filefMRI = os.path.join(funcInDir, imagefMRI)
fileMask = os.path.join(funcInDir, imageMask)
mask_img = nib.load(fileMask)

SeitzDir = '/projects/b1081/Atlases/Seitzman300/'
labels_img = nib.load(SeitzDir+'Seitzman300_MNI_res02_allROIs.nii.gz')
# ^ Not going to work. Only cortical labels
labels_path = SeitzDir+'ROIs_anatomicalLabels.txt'
labels_df = pd.read_csv(labels_path, sep='\t')
labels_df = labels_df.rename(columns={'0=cortexMid,1=cortexL,2=cortexR,3=hippocampus,4=amygdala,5=basalGanglia,6=thalamus,7=cerebellum': 'region'})

labels_list = labels_df.iloc[:, 0] # will want to truncate names
confounds_path = os.path.join(funcInDir, [x for x in fList if ('confounds_timeseries.tsv' in x)][0])
confounds_df = pd.read_csv(confounds_path, sep='\t')
os.makedirs(os.path.join(outDir, sub, ses), exist_ok=True)
param_file = open(os.path.join(funcInDir, sub+'_'+ses+'_task-rest_run-1_space-MNI152NLin6Asym_desc-preproc_bold.json'),)
param_df = json.load(param_file)

#### Calculate confounds
# TO DO: Make it what Zach does
confounds_df = confounds_df.loc[10:] # drop the first 10 TRs from confounds df
confound_vars = ['trans_x','trans_y','trans_z',
                 'rot_x','rot_y','rot_z',
                 'global_signal', 'csf',
                 'white_matter']
derivative_columns = ['{}_derivative1'.format(c) for c
                     in confound_vars]
power_columns = ['{}_derivative1_power2'.format(c) for c
                     in confound_vars]
final_confounds = confound_vars + derivative_columns + power_columns
confounds_df = confounds_df[final_confounds]

#### Remove first 10 TRs
#https://carpentries-incubator.github.io/SDC-BIDS-fMRI/05-data-cleaning-with-nilearn/index.html
raw_func_img = nib.load(filefMRI)
func_img = raw_func_img.slicer[:,:,:,10:]

# read docs: detrend, low_pass, high_pass (should depend on TR?)
masker = NiftiLabelsMasker(labels_img=labels_img,
                            labels=labels_list,
                            mask_img=mask_img,
                            smoothing_fwhm=6,
                            standardize=True, #Check if fMRI does this
                            detrend=True,
                            low_pass=.08,
                            high_pass=.01,
                            verbose=5,
                            t_r=param_df['RepetitionTime']
                        )

time_series = masker.fit_transform(func_img, confounds=confounds_df)

correlation_measure = ConnectivityMeasure(kind='correlation')
correlation_matrix = correlation_measure.fit_transform([time_series])[0]

# Write out time series
np.savetxt(outDir+sub+'/'+ses+'/'+sub+'_'+ses+'_seitz_timeseries.csv',
    time_series, delimiter=',')

# Write out correlation matrix
np.savetxt(outDir+sub+'/'+ses+'/'+sub+'_'+ses+'_seitz_corrmat.csv',
    correlation_matrix, delimiter=',')

# Write out average amygdala connectivity
amyg_indices = labels_df[labels_df['region'] == 4].index
amyg_corr = correlation_matrix[amyg_indices]
amyg_ave_corr = (amyg_corr[0,] + amyg_corr[1,])/2 # average across right and left
amyg_cols = ['region'+str(x) for x in range(1,301)]
amyg_df = pd.DataFrame(columns = amyg_cols)
amyg_df.loc[0] = amyg_ave_corr.T
amyg_df['subid'] = sub.split('-')[1]
amyg_df['sesid'] = ses.split('-')[1]
cols = ['subid', 'sesid']
cols.extend(amyg_cols)
amyg_df = amyg_df[cols]

amyg_df.to_csv(outDir+sub+'/'+ses+'/'+sub+'_'+ses+'_seitz_amygcorr.csv', index=False)

# Make a large figure, masking the main diagonal for visualization:
#np.fill_diagonal(correlation_matrix, 0)

# The labels we have start with the background (0), hence we skip the first label.
# matrices are ordered for block-like representation
#https://nilearn.github.io/modules/generated/nilearn.plotting.plot_matrix.html
# TO DO: This isn't working
#plotting.plot_matrix(correlation_matrix, figure=(10, 8), labels=amyg_cols,
#                     vmax=0.8, vmin=-0.8, reorder=True,
#                     output_file=outDir+sub+'/'+ses+'/'+sub+'_'+ses+'_corrmat.png')
