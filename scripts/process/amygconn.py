### This script conducts the post-processing steps after fmriprep
###
### Ellyn Butler
### November 22, 2021 - October 20, 2022

# Python version: 3.8.4
import os
import json
import pandas as pd #1.0.5
import nibabel as nib #3.2.1
import numpy as np #1.19.1
#from bids.layout import BIDSLayout #may not be needed
from nilearn.input_data import NiftiLabelsMasker #0.8.1
from nilearn import plotting
from nilearn import signal
from nilearn import image
import matplotlib
matplotlib.use('pdf')
import matplotlib.pyplot as plt
import scipy.signal as sgnl
import sys, getopt
import argparse
from postproc_rest import postproc_rest
from postproc_avoid import postproc_avoid
from postproc_faces import postproc_faces

parser = argparse.ArgumentParser()
parser.add_argument('-i', default='/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep/')
parser.add_argument('-o', default='/projects/b1108/studies/mwmh/data/processed/neuroimaging/amygconn/')
parser.add_argument('-b', default='/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/')
parser.add_argument('-s')
parser.add_argument('-ss')
parser.add_argument('-t', nargs='+') #https://www.codegrepper.com/code-examples/python/python+argparse+multiple+values
args = parser.parse_args()

indir = args.i #indir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep/'
outdir = args.o #outdir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/amygconn/'
bidsdir = args.b #bidsdir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/raw/neuroimaging/bids/'
sub = args.s #sub = 'sub-MWMH359'
ses = args.ss #ses = 'ses-1'
tasks = args.t

# Directory where preprocessed fMRI data is located
subindir = os.path.join(indir, sub)
sesindir = os.path.join(subindir, ses)
funcindir = os.path.join(sesindir, 'func')

# Directory where outputs should go
suboutdir = os.path.join(outdir, sub)
sesoutdir = os.path.join(suboutdir, ses)
os.makedirs(os.path.join(outdir, sub, ses), exist_ok=True)

# Get the bids directory for this session
bidssubdir = os.path.join(bidsdir, sub)
bidssesdir = os.path.join(bidssubdir, ses)

# Get the labeled image and labels
seitzdir = '/projects/b1081/Atlases/Seitzman300/' #seitzdir='/Users/flutist4129/Documents/Northwestern/templates/Seitzman300/'
labels_img = nib.load(seitzdir+'Seitzman300_MNI_res02_allROIs.nii.gz')
labels_path = seitzdir+'ROIs_anatomicalLabels.txt'
labels_df = pd.read_csv(labels_path, sep='\t')
labels_df = labels_df.rename(columns={'0=cortexMid,1=cortexL,2=cortexR,3=hippocampus,4=amygdala,5=basalGanglia,6=thalamus,7=cerebellum': 'region'})
labels_list = labels_df.iloc[:, 0] # will want to truncate names

############################ Process available tasks ###########################

if 'rest' in tasks:
    rest_corr_matrix, rest_qual_df = postproc_rest(sub, ses, funcindir, bidssesdir, sesoutdir)
if 'avoid' in tasks:
    avoid_corr_matrix, avoid_qual_df = postproc_avoid(sub, ses, funcindir, bidssesdir, sesoutdir)
if 'faces' in tasks:
    faces_corr_matrix, faces_qual_df = postproc_faces(sub, ses, funcindir, bidssesdir, sesoutdir)

################################# Combine tasks ################################

if 'rest' in tasks and 'avoid' in tasks and 'faces' in tasks:
    # Combine quality metrics
    qual_df = pd.concat([rest_qual_df, avoid_qual_df, faces_qual_df])
    qual_df.to_csv(sesoutdir+'/'+sub+'_'+ses+'_quality.csv', index=False)
    # Average correlation matrices
    corr_matrix = (rest_corr_matrix + avoid_corr_matrix + faces_corr_matrix)/3
elif 'rest' in tasks and 'avoid' in tasks:
    # Combine quality metrics
    qual_df = pd.concat([rest_qual_df, avoid_qual_df])
    qual_df.to_csv(sesoutdir+'/'+sub+'_'+ses+'_quality.csv', index=False)
    # Average correlation matrices
    corr_matrix = (rest_corr_matrix + avoid_corr_matrix)/2
elif 'rest' in tasks and 'faces' in tasks:
    # Combine quality metrics
    qual_df = pd.concat([rest_qual_df, faces_qual_df])
    qual_df.to_csv(sesoutdir+'/'+sub+'_'+ses+'_quality.csv', index=False)
    # Average correlation matrices
    corr_matrix = (rest_corr_matrix + faces_corr_matrix)/2
elif 'avoid' in tasks and 'faces' in tasks:
    # Combine quality metrics
    qual_df = pd.concat([avoid_qual_df, faces_qual_df])
    qual_df.to_csv(sesoutdir+'/'+sub+'_'+ses+'_quality.csv', index=False)
    # Average correlation matrices
    corr_matrix = (avoid_corr_matrix + faces_corr_matrix)/2
elif 'rest' in tasks:
    qual_df = rest_qual_df
    qual_df.to_csv(sesoutdir+'/'+sub+'_'+ses+'_quality.csv', index=False)
    corr_matrix = rest_corr_matrix
elif 'avoid' in tasks:
    qual_df = avoid_qual_df
    qual_df.to_csv(sesoutdir+'/'+sub+'_'+ses+'_quality.csv', index=False)
    corr_matrix = avoid_corr_matrix
elif 'faces' in tasks:
    qual_df = faces_qual_df
    qual_df.to_csv(sesoutdir+'/'+sub+'_'+ses+'_quality.csv', index=False)
    corr_matrix = faces_corr_matrix

# Create correlation matrix plot
plt.ioff()
corr_mat_plt = plt.matshow(corr_matrix)
plt.savefig(sesoutdir+'/'+sub+'_'+ses+'_corrmat.pdf')

# Write out correlation matrix
np.savetxt(sesoutdir+'/'+sub+'_'+ses+'_atlas-seitz_corrmat.csv',
    corr_matrix, delimiter=',')

##### Write out average amygdala connectivity
# Get amygdalae indices and average connectivity
amyg_indices = labels_df[labels_df['region'] == 4].index
amyg_corr = corr_matrix[amyg_indices]
amyg_ave_corr = (amyg_corr[0,] + amyg_corr[1,])/2 # average across right and left

# Name columns
amyg_cols = ['region'+str(x) for x in range(1,301)]
amyg_df = pd.DataFrame(columns = amyg_cols)
amyg_df.loc[0] = amyg_ave_corr.T
amyg_df['subid'] = subid
amyg_df['sesid'] = sesid
cols = ['subid', 'sesid']
cols.extend(amyg_cols)
amyg_df = amyg_df[cols]

amyg_df.to_csv(sesoutdir+'/'+sub+'_'+ses+'_atlas-seitz_amygcorr.csv', index=False)
