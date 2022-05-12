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
parser.add_argument('-i', default='/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep/')
parser.add_argument('-o', default='/projects/b1108/studies/mwmh/data/processed/neuroimaging/amygconn/')
parser.add_argument('-b', default='/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/')
parser.add_argument('-s')
parser.add_argument('-ss')
args = parser.parse_args()

bidsDir =
inDir = args.i #inDir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep/'
outDir = args.o #outDir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/amygconn/'
bidsDir = args.b #bidsDir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/raw/neuroimaging/bids/'
sub = args.s #sub = 'sub-MWMH378'
ses = args.ss #ses = 'ses-1'

# directory where preprocessed fMRI data is located
subInDir = os.path.join(inDir, sub)
sesInDir = os.path.join(subInDir, ses)
funcInDir = os.path.join(sesInDir, 'func')

# location of the pre-processed fMRI & mask
fList = os.listdir(funcInDir)
imageRest = [x for x in fList if ('preproc_bold.nii.gz' in x and 'task-rest' in x)][0]
imageAvoid = [x for x in fList if ('preproc_bold.nii.gz' in x and 'task-avoid' in x)][0]
imageFaces = [x for x in fList if ('preproc_bold.nii.gz' in x and 'task-faces' in x)][0]
imageMask = [x for x in fList if ('brain_mask.nii.gz' in x)][0]

fileRest = os.path.join(funcInDir, imageRest)
fileAvoid = os.path.join(funcInDir, imageAvoid)
fileFaces = os.path.join(funcInDir, imageFaces)
fileMask = os.path.join(funcInDir, imageMask)
mask_img = nib.load(fileMask)

SeitzDir = '/projects/b1081/Atlases/Seitzman300/' #SeitzDir='/Users/flutist4129/Documents/Northwestern/templates/Seitzman300/'
labels_img = nib.load(SeitzDir+'Seitzman300_MNI_res02_allROIs.nii.gz')
# ^ Not going to work. Only cortical labels
labels_path = SeitzDir+'ROIs_anatomicalLabels.txt'
labels_df = pd.read_csv(labels_path, sep='\t')
labels_df = labels_df.rename(columns={'0=cortexMid,1=cortexL,2=cortexR,3=hippocampus,4=amygdala,5=basalGanglia,6=thalamus,7=cerebellum': 'region'})

labels_list = labels_df.iloc[:, 0] # will want to truncate names

# Load confounds for rest, avoid and faces
confounds_rest_path = os.path.join(funcInDir, [x for x in fList if ('task-rest_desc-confounds_timeseries.tsv' in x)][0])
confounds_rest_df = pd.read_csv(confounds_rest_path, sep='\t')
confounds_avoid_path = os.path.join(funcInDir, [x for x in fList if ('task-avoid_desc-confounds_timeseries.tsv' in x)][0])
confounds_avoid_df = pd.read_csv(confounds_avoid_path, sep='\t')
confounds_faces_path = os.path.join(funcInDir, [x for x in fList if ('task-faces_desc-confounds_timeseries.tsv' in x)][0])
confounds_faces_df = pd.read_csv(confounds_faces_path, sep='\t')
os.makedirs(os.path.join(outDir, sub, ses), exist_ok=True)

# Load task events for avoid and faces
bidsSubDir = os.path.join(bidsDir, sub)
bidsSesDir = os.path.join(bidsSubDir, ses)
events_avoid_df = pd.read_csv(bidsSesDir+'/func/'+sub+'_'+ses+'_task-avoid_events.tsv', sep='\t')
events_faces_df = pd.read_csv(bidsSesDir+'/func/'+sub+'_'+ses+'_task-faces_events.tsv', sep='\t')

# Load parameters for rest, avoid and faces
param_rest_file = open(os.path.join(funcInDir, sub+'_'+ses+'_task-rest_space-MNI152NLin6Asym_desc-preproc_bold.json'),)
param_rest_df = json.load(param_rest_file)
param_avoid_file = open(os.path.join(funcInDir, sub+'_'+ses+'_task-avoid_space-MNI152NLin6Asym_desc-preproc_bold.json'),)
param_avoid_df = json.load(param_avoid_file)
param_faces_file = open(os.path.join(funcInDir, sub+'_'+ses+'_task-faces_space-MNI152NLin6Asym_desc-preproc_bold.json'),)
param_faces_df = json.load(param_faces_file)

#### Calculate confounds
confound_vars = ['trans_x','trans_y','trans_z',
                 'rot_x','rot_y','rot_z',
                 'global_signal', 'csf',
                 'white_matter']
derivative_columns = ['{}_derivative1'.format(c) for c
                     in confound_vars]
power_columns = ['{}_derivative1_power2'.format(c) for c
                     in confound_vars]
final_confounds = confound_vars + derivative_columns + power_columns

## REST
confounds_rest_df = confounds_rest_df.loc[5:] # drop the first 5 TRs from confounds df
confounds_rest_df = confounds_rest_df[final_confounds]

## AVOID (onset: 12)
confounds_avoid_df = confounds_avoid_df.loc[6:] # drop the first 6 TRs from confounds df
confounds_avoid_df = confounds_avoid_df[final_confounds]
# subtract off 6 TRs*RT 2 = 12 from the onset column
events_avoid_df['onset'] = events_avoid_df['onset'] - 12

## FACES (onset: 14.5)
confounds_faces_df = confounds_faces_df.loc[5:] # drop the first 5 TRs from confounds df
confounds_faces_df = confounds_faces_df[final_confounds]
# subtract off 5 TRs*RT 2 = 10 from the onset column
events_faces_df['onset'] = events_faces_df['onset'] - 10

#### Remove first X TRs
#https://carpentries-incubator.github.io/SDC-BIDS-fMRI/05-data-cleaning-with-nilearn/index.html
# REST: Remove first 5 TRs
raw_rest_img = nib.load(fileRest)
rest_img = raw_rest_img.slicer[:,:,:,5:]

# AVOID: Remove first 6 TRs
raw_avoid_img = nib.load(fileAvoid)
avoid_img = raw_avoid_img.slicer[:,:,:,6:]

# FACES: Remove first 5 TRs
raw_faces_img = nib.load(fileFaces)
faces_img = raw_faces_img.slicer[:,:,:,5:]

# read docs: detrend, low_pass, high_pass (should depend on TR?)
masker_rest = NiftiLabelsMasker(labels_img=labels_img,
                            labels=labels_list,
                            mask_img=mask_img,
                            smoothing_fwhm=0,
                            standardize=True,
                            detrend=True,
                            low_pass=.08,
                            high_pass=.01,
                            verbose=5,
                            t_r=param_rest_df['RepetitionTime']
                        )
masker_avoid = NiftiLabelsMasker(labels_img=labels_img,
                            labels=labels_list,
                            mask_img=mask_img,
                            smoothing_fwhm=0,
                            standardize=True,
                            detrend=True,
                            low_pass=.08,
                            high_pass=.01,
                            verbose=5,
                            t_r=param_avoid_df['RepetitionTime']
                        )
masker_faces = NiftiLabelsMasker(labels_img=labels_img,
                            labels=labels_list,
                            mask_img=mask_img,
                            smoothing_fwhm=0,
                            standardize=True,
                            detrend=True,
                            low_pass=.08,
                            high_pass=.01,
                            verbose=5,
                            t_r=param_faces_df['RepetitionTime']
                        )
# Run masker on all scans
rest_time_series = masker_rest.fit_transform(rest_img, confounds=confounds_rest_df)
avoid_time_series = masker_avoid.fit_transform(avoid_img, confounds=confounds_avoid_df)
faces_time_series = masker_faces.fit_transform(faces_img, confounds=confounds_faces_df)

############################### Regress out task ###############################
# TO DO: need to use NiftiLabelsMasker to do everything but the masking so that
# I can model the task after post processing, and then apply the masker again
# to only get the times series from the ROIs

# AVOID


# FACES

################################# Connectivity #################################
# Write out time series
np.savetxt(outDir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-rest_atlas-seitz_timeseries.csv',
    rest_time_series, delimiter=',')
np.savetxt(outDir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-avoid_atlas-seitz_timeseries.csv',
    avoid_time_series, delimiter=',')
np.savetxt(outDir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-faces_atlas-seitz_timeseries.csv',
    faces_time_series, delimiter=',')

time_series = [rest_time_series, avoid_time_series, faces_time_series]

correlation_measure = ConnectivityMeasure(kind='correlation')
correlation_matrix = correlation_measure.fit_transform(time_series)[0]

# Write out correlation matrix
np.savetxt(outDir+sub+'/'+ses+'/'+sub+'_'+ses+'_atlas-seitz_corrmat.csv',
    correlation_matrix, delimiter=',')

##### Write out average amygdala connectivity
# Get amygdalae indices and average connectivity
amyg_indices = labels_df[labels_df['region'] == 4].index
amyg_corr = correlation_matrix[amyg_indices]
amyg_ave_corr = (amyg_corr[0,] + amyg_corr[1,])/2 # average across right and left

# Remove the elements corresponding to the amygdalae
not_amyg_indices = labels_df[labels_df['region'] != 4].index
amyg_ave_corr = amyg_ave_corr[not_amyg_indices]

# Name columns
amyg_cols = ['region'+str(x) for x in range(1,301)]
amyg_df = pd.DataFrame(columns = amyg_cols)
amyg_df.loc[0] = amyg_ave_corr.T
amyg_df['subid'] = sub.split('-')[1]
amyg_df['sesid'] = ses.split('-')[1]
cols = ['subid', 'sesid']
cols.extend(amyg_cols)
amyg_df = amyg_df[cols]

amyg_df.to_csv(outDir+sub+'/'+ses+'/'+sub+'_'+ses+'_atlas-seitz_amygcorr.csv', index=False)

# Make a large figure, masking the main diagonal for visualization:
#np.fill_diagonal(correlation_matrix, 0)

# The labels we have start with the background (0), hence we skip the first label.
# matrices are ordered for block-like representation
#https://nilearn.github.io/modules/generated/nilearn.plotting.plot_matrix.html
# TO DO: This isn't working
#plotting.plot_matrix(correlation_matrix, figure=(10, 8), labels=amyg_cols,
#                     vmax=0.8, vmin=-0.8, reorder=True,
#                     output_file=outDir+sub+'/'+ses+'/'+sub+'_'+ses+'_corrmat.png')
