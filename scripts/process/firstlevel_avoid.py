### This script runs first levels models for the avoid task
### https://nilearn.github.io/dev/glm/first_level_model.html
### https://nilearn.github.io/dev/auto_examples/04_glm_first_level/plot_adhd_dmn.html#sphx-glr-auto-examples-04-glm-first-level-plot-adhd-dmn-py
###
### Ellyn Butler
### September 20, 2022

import os
import json
import pandas as pd
import nibabel as nib
from nilearn.glm.first_level import make_first_level_design_matrix
from nilearn.plotting import plot_design_matrix
from nilearn.glm.first_level import FirstLevelModel
import numpy as np

sub = 'sub-MWMH378'
ses = 'ses-1'

inDir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep/'
subInDir = os.path.join(inDir, sub)
sesInDir = os.path.join(subInDir, ses)
funcInDir = os.path.join(sesInDir, 'func')

bidsDir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/raw/neuroimaging/bids/'

fList = os.listdir(funcInDir)
imageAvoid = [x for x in fList if ('preproc_bold.nii.gz' in x and 'task-avoid' in x)][0]
fileAvoid = os.path.join(funcInDir, imageAvoid)

bidsSubDir = os.path.join(bidsDir, sub)
bidsSesDir = os.path.join(bidsSubDir, ses)
events_avoid_df = pd.read_csv(bidsSesDir+'/func/'+sub+'_'+ses+'_task-avoid_events.tsv', sep='\t')

param_avoid_file = open(os.path.join(funcInDir, sub+'_'+ses+'_task-avoid_space-MNI152NLin6Asym_desc-preproc_bold.json'),)
param_avoid_df = json.load(param_avoid_file)

avoid_img = nib.load(fileAvoid)

#n_scans = avoid_img.shape[3]
#t_r = param_avoid_df['RepetitionTime']
#frame_times = np.linspace(0, (n_scans - 1) * t_r, n_scans)

# Transform the events dataframe so that for each unique combination of indicators
# there is a different level of a categorical variable (nilearn seems to require
# a trial_type column)
# https://stackoverflow.com/questions/50607740/reverse-a-get-dummies-encoding-in-pandas

categ = events_avoid_df.iloc[:, 3:].idxmax(axis=1)
events_categ_avoid_df = events_avoid_df.iloc[:, 0:2]
events_categ_avoid_df['trial_type'] = categ

avoid_model = FirstLevelModel(param_avoid_df['RepetitionTime'],
                              noise_model='ar1',
                              standardize=False,
                              hrf_model='spm + derivative + dispersion',
                              drift_model='cosine')
avoid_glm = avoid_model.fit(avoid_img, events_categ_avoid_df)
design_matrices = avoid_glm.design_matrices #design_matrices.keys() >>> AttributeError: 'list' object has no attribute 'keys'
plot_design_matrix(design_matrices) # September 20, 2022: Failing here

# Compute contrasts

#design_matrices = make_first_level_design_matrix(frame_times, events,
#                          drift_model='polynomial', drift_order=3)







#
