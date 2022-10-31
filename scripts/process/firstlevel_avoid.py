### This script runs first levels models for the avoid task
### https://nilearn.github.io/dev/glm/first_level_model.html
### https://nilearn.github.io/dev/auto_examples/04_glm_first_level/plot_adhd_dmn.html#sphx-glr-auto-examples-04-glm-first-level-plot-adhd-dmn-py
###
### Ellyn Butler
### September 20, 2022 - October 31, 2022

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
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('-i', default='/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep/')
parser.add_argument('-o', default='/projects/b1108/studies/mwmh/data/processed/neuroimaging/firstlevel/')
parser.add_argument('-b', default='/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/')
parser.add_argument('-s')
parser.add_argument('-ss')
args = parser.parse_args()

indir = args.i #indir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep/'
outdir = args.o #outdir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/amygconn/'
bidsdir = args.b #bidsdir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/raw/neuroimaging/bids/'
sub = args.s #sub = 'sub-MWMH359'
ses = args.ss #ses = 'ses-1'

subindir = os.path.join(indir, sub)
sesindir = os.path.join(subindir, ses)
funcindir = os.path.join(sesindir, 'func')

os.makedirs(os.path.join(outdir, sub, ses), exist_ok=True)

flist = os.listdir(funcindir)
imageAvoid = [x for x in flist if ('preproc_bold.nii.gz' in x and 'task-avoid' in x)][0] #'sub-MWMH378_ses-1_task-avoid_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz'
fileAvoid = os.path.join(funcindir, imageAvoid)

bidssubdir = os.path.join(bidsdir, sub)
bidssesdir = os.path.join(bidssubdir, ses)
events_avoid_df = pd.read_csv(bidssesdir+'/func/'+sub+'_'+ses+'_task-avoid_events.tsv', sep='\t')

param_avoid_file = open(os.path.join(funcindir, sub+'_'+ses+'_task-avoid_space-MNI152NLin6Asym_desc-preproc_bold.json'),)
param_avoid_df = json.load(param_avoid_file)

avoid_img = nib.load(fileAvoid)

imageMask = [x for x in flist if ('brain_mask.nii.gz' in x)][0] #'sub-MWMH378_ses-1_task-avoid_space-MNI152NLin6Asym_desc-brain_mask.nii.gz'
fileMask = os.path.join(funcindir, imageMask)
mask_img = nib.load(fileMask)

### Specify confounds
confounds_avoid_path = os.path.join(funcindir, [x for x in flist if ('task-avoid_desc-confounds_timeseries.tsv' in x)][0])
confounds_avoid_df = pd.read_csv(confounds_avoid_path, sep='\t')

confound_vars = ['trans_x','trans_y','trans_z',
                 'rot_x','rot_y','rot_z', 'global_signal'] #, 'csf', 'white_matter'
deriv_vars = ['{}_derivative1'.format(c) for c
                     in confound_vars]
power_vars = ['{}_power2'.format(c) for c
                     in confound_vars]
power_deriv_vars = ['{}_derivative1_power2'.format(c) for c
                     in confound_vars]
#final_confounds = confound_vars + deriv_vars + power_vars + power_deriv_vars
final_confounds = confound_vars

confounds_avoid_df = confounds_avoid_df[final_confounds]

### Replace NaNs in confounds df with 0s - NOT CLEAR THAT I SHOULD DO THIS ~~~~~~~~~~~~~~~~~~~~~~~~
confounds_avoid_df = confounds_avoid_df.fillna(0)

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

# Remove fixation rows
events_categ_avoid_df = events_categ_avoid_df[~events_categ_avoid_df['trial_type'].str.contains('fix')]
events_categ_avoid_df = events_categ_avoid_df[~events_categ_avoid_df['trial_type'].str.contains('blank')]

# Specify model
avoid_model = FirstLevelModel(param_avoid_df['RepetitionTime'],
                              mask_img=mask_img,
                              noise_model='ar1',
                              standardize=False,
                              hrf_model='spm + derivative + dispersion',
                              drift_model='cosine',
                              smoothing_fwhm=4)
avoid_glm = avoid_model.fit(avoid_img, events_categ_avoid_df, confounds=confounds_avoid_df)
#Warning: Matrix is singular at working precision, regularizing... Where is this coming from in the design matrix?
#WHAT IS GOING ON HERE? UserWarning: Mean values of 0 observed.The data have probably been centered.Scaling might not work as expected?
#avoid_glm.generate_report() #missing 1 required positional argument: 'contrasts'
design_matrix = avoid_model.design_matrices_[0]
plot_design_matrix(design_matrix, output_file=outdir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-avoid_design_matrix.pdf')

#design_matrices = make_first_level_design_matrix(frame_times, events,
#                          drift_model='polynomial', drift_order=3)

############################### Compute contrasts ##############################

#https://nilearn.github.io/stable/auto_examples/04_glm_first_level/plot_first_level_details.html

### Make contrasts
approach = np.array([])
avoid = np.array([])
gain = np.array([])
lose = np.array([])

exclude = ['derivative', 'dispersion', 'drift', 'constant', 'trans', 'rot', 'global', 'csf', 'white']
for key in design_matrix.keys():
    if not any(exc in key for exc in exclude):
        if 'approach' in key:
            approach = np.append(approach, 1)
            avoid = np.append(avoid, 0)
            gain = np.append(gain, 0)
            lose = np.append(lose, 0)
        elif 'avoid' in key:
            approach = np.append(approach, 0)
            avoid = np.append(avoid, 1)
            gain = np.append(gain, 0)
            lose = np.append(lose, 0)
        elif 'gain' in key:
            approach = np.append(approach, 0)
            avoid = np.append(avoid, 0)
            gain = np.append(gain, 1)
            lose = np.append(lose, 0)
        elif 'lose' in key:
            approach = np.append(approach, 0)
            avoid = np.append(avoid, 0)
            gain = np.append(gain, 0)
            lose = np.append(lose, 1)
        else:
            approach = np.append(approach, 0)
            avoid = np.append(avoid, 0)
            gain = np.append(gain, 0)
            lose = np.append(lose, 0)
    else:
        approach = np.append(approach, 0)
        avoid = np.append(avoid, 0)
        gain = np.append(gain, 0)
        lose = np.append(lose, 0)


contrasts = {'approach_minus_avoid': np.subtract(approach, avoid),
             'gain_minus_lose': np.subtract(gain, lose)
            }

### Approach minus avoid
plot_contrast_matrix(contrasts['approach_minus_avoid'], design_matrix=design_matrix,
                        output_file=outdir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-avoid_approach_minus_avoid_contrast_matrix.pdf')

approach_minus_avoid_z_map = avoid_model.compute_contrast(
    contrasts['approach_minus_avoid'], output_type='z_score')

approach_minus_avoid_z_map.to_filename(outdir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-faces_approach_minus_avoid_zmap.nii.gz')

plotting.plot_stat_map(approach_minus_avoid_z_map, threshold=2.0,
              display_mode='z', cut_coords=3, title='Approach minus Avoid (Z>2)',
              output_file=outdir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-avoid_approach_minus_avoid_zmap.pdf')
# TO DO: Unthresholded indicated that the mask may not fit the brain well... vmPFC cut off

### Gain minus lose
plot_contrast_matrix(contrasts['gain_minus_lose'], design_matrix=design_matrix,
                        output_file=outdir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-avoid_gain_minus_lose_contrast_matrix.pdf')

gain_minus_lose_z_map = avoid_model.compute_contrast(
    contrasts['gain_minus_lose'], output_type='z_score')

gain_minus_lose_z_map.to_filename(outdir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-faces_gain_minus_lose_zmap.nii.gz')

plotting.plot_stat_map(gain_minus_lose_z_map, threshold=2.0,
              display_mode='z', cut_coords=2, title='Gain minus Lose (Z>2)',
              output_file=outdir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-avoid_gain_minus_lose_zmap.pdf')







#
