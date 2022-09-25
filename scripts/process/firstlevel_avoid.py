### This script runs first levels models for the avoid task
### https://nilearn.github.io/dev/glm/first_level_model.html
### https://nilearn.github.io/dev/auto_examples/04_glm_first_level/plot_adhd_dmn.html#sphx-glr-auto-examples-04-glm-first-level-plot-adhd-dmn-py
###
### Ellyn Butler
### September 20, 2022 - September 22, 2022

import os
import json
import pandas as pd
import nibabel as nib
from nilearn.glm.first_level import make_first_level_design_matrix
from nilearn.plotting import plot_design_matrix
from nilearn.glm.first_level import FirstLevelModel
import numpy as np
import matplotlib.pyplot as plt
from nilearn.plotting import plot_contrast_matrix
from nilearn import plotting

sub = 'sub-MWMH378'
ses = 'ses-1'

inDir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep/'
subInDir = os.path.join(inDir, sub)
sesInDir = os.path.join(subInDir, ses)
funcInDir = os.path.join(sesInDir, 'func')

outDir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/firstlevel/'
os.makedirs(os.path.join(outDir, sub, ses), exist_ok=True)

bidsDir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/raw/neuroimaging/bids/'

fList = os.listdir(funcInDir)
imageAvoid = [x for x in fList if ('preproc_bold.nii.gz' in x and 'task-avoid' in x)][0] #'sub-MWMH378_ses-1_task-avoid_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz'
fileAvoid = os.path.join(funcInDir, imageAvoid)

bidsSubDir = os.path.join(bidsDir, sub)
bidsSesDir = os.path.join(bidsSubDir, ses)
events_avoid_df = pd.read_csv(bidsSesDir+'/func/'+sub+'_'+ses+'_task-avoid_events.tsv', sep='\t')

param_avoid_file = open(os.path.join(funcInDir, sub+'_'+ses+'_task-avoid_space-MNI152NLin6Asym_desc-preproc_bold.json'),)
param_avoid_df = json.load(param_avoid_file)

avoid_img = nib.load(fileAvoid)

imageMask = [x for x in fList if ('brain_mask.nii.gz' in x)][0] #'sub-MWMH378_ses-1_task-avoid_space-MNI152NLin6Asym_desc-brain_mask.nii.gz'
fileMask = os.path.join(funcInDir, imageMask)
mask_img = nib.load(fileMask)

#n_scans = avoid_img.shape[3]
#t_r = param_avoid_df['RepetitionTime']
#frame_times = np.linspace(0, (n_scans - 1) * t_r, n_scans)

### Transform the events dataframe so that for each unique combination of indicators
### there is a different level of a categorical variable (nilearn seems to require
### a trial_type column)
# https://stackoverflow.com/questions/50607740/reverse-a-get-dummies-encoding-in-pandas

cols = ['fix1', 'fix2', 'approach', 'avoid', 'nothing', 'gain50', 'gain10',
       'lose10', 'lose50']
for col in cols:
    events_avoid_df[col] = events_avoid_df[col].map(str)

categ = events_avoid_df.apply(lambda x: ''.join(x[cols]),axis=1)
events_categ_avoid_df = events_avoid_df.iloc[:, 0:2]
events_categ_avoid_df['trial_type'] = categ
#categ.unique()

### Fit first level model

#https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.replace.html
events_categ_avoid_df = events_categ_avoid_df.replace({'trial_type': {'000100000':'avoid',
                            '100000000':'fix1', '000000100':'gain10',
                            '010000000':'fix2', '001000000':'approach',
                            '000000010':'lose10', '000001000':'gain50',
                            '000000001':'lose50'}})

avoid_model = FirstLevelModel(param_avoid_df['RepetitionTime'],
                              mask_img=mask_img,
                              noise_model='ar1',
                              standardize=False,
                              hrf_model='spm + derivative + dispersion',
                              drift_model='cosine')
avoid_glm = avoid_model.fit(avoid_img, events_categ_avoid_df)
avoid_glm.generate_report()
design_matrix = avoid_model.design_matrices_[0]
plot_design_matrix(design_matrix, output_file=outDir+sub+'/'+ses+'/'+sub+'_'+ses+'_design_matrix.pdf')

#design_matrices = make_first_level_design_matrix(frame_times, events,
#                          drift_model='polynomial', drift_order=3)

############################### Compute contrasts ##############################

#https://nilearn.github.io/stable/auto_examples/04_glm_first_level/plot_first_level_details.html

n_columns = design_matrix.shape[1]

def pad_vector(contrast_, n_columns):
    """A small routine to append zeros in contrast vectors"""
    return np.hstack((contrast_, np.zeros(n_columns - len(contrast_))))

contrasts = {'approach_minus_avoid': pad_vector([1, 0, 0, -1], n_columns),
             'gain_minus_lose': pad_vector([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, -1, 0, 0, -1], n_columns),
             'gain_minus_fix': pad_vector([0, 0, 0, 0, 0, 0, -1, 0, 0, -1, 0, 0, 1, 0, 0, 1], n_columns)
            }

### Approach minus avoid
plot_contrast_matrix(contrasts['approach_minus_avoid'], design_matrix=design_matrix,
                        output_file=outDir+sub+'/'+ses+'/'+sub+'_'+ses+'_approach_minus_avoid_contrast_matrix.pdf')

approach_minus_avoid_z_map = avoid_model.compute_contrast(
    contrasts['approach_minus_avoid'], output_type='z_score')

plotting.plot_stat_map(approach_minus_avoid_z_map, threshold=3.0,
              display_mode='z', cut_coords=3, title='Approach minus Avoid (Z>3)',
              output_file=outDir+sub+'/'+ses+'/'+sub+'_'+ses+'_approach_minus_avoid_zmap.pdf')
# TO DO: Unthresholded indicated that the mask may not fit the brain well... vmPFC cut off

### Gain minus lose
plot_contrast_matrix(contrasts['gain_minus_lose'], design_matrix=design_matrix,
                        output_file=outDir+sub+'/'+ses+'/'+sub+'_'+ses+'_gain_minus_lose_contrast_matrix.pdf')

gain_minus_lose_z_map = avoid_model.compute_contrast(
    contrasts['gain_minus_lose'], output_type='z_score')

plotting.plot_stat_map(gain_minus_lose_z_map, threshold=3.0,
              display_mode='z', cut_coords=3, title='Gain minus Lose (Z>3)',
              output_file=outDir+sub+'/'+ses+'/'+sub+'_'+ses+'_gain_minus_lose_zmap.pdf')

### Gain minus fix (Greg's "reward" contrast)
plot_contrast_matrix(contrasts['gain_minus_fix'], design_matrix=design_matrix,
              output_file=outDir+sub+'/'+ses+'/'+sub+'_'+ses+'_gain_minus_fix_contrast_matrix.pdf')

gain_minus_fix_z_map = avoid_model.compute_contrast(
    contrasts['gain_minus_fix'], output_type='z_score')

plotting.plot_stat_map(gain_minus_fix_z_map, threshold=3.0,
              display_mode='z', cut_coords=3, title='Gain minus Fix (Z>3)',
              output_file=outDir+sub+'/'+ses+'/'+sub+'_'+ses+'_gain_minus_fix_zmap.pdf')








#
