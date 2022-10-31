### This script runs first levels models for the faces task
### https://nilearn.github.io/dev/glm/first_level_model.html
### https://nilearn.github.io/dev/auto_examples/04_glm_first_level/plot_adhd_dmn.html#sphx-glr-auto-examples-04-glm-first-level-plot-adhd-dmn-py
###
### Ellyn Butler
### September 28, 2022 - October 31, 2022

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
imagefaces = [x for x in flist if ('preproc_bold.nii.gz' in x and 'task-faces' in x)][0] #'sub-MWMH378_ses-1_task-faces_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz'
filefaces = os.path.join(funcindir, imagefaces)

bidssubdir = os.path.join(bidsdir, sub)
bidssesdir = os.path.join(bidssubdir, ses)
events_faces_df = pd.read_csv(bidssesdir+'/func/'+sub+'_'+ses+'_task-faces_events.tsv', sep='\t')

param_faces_file = open(os.path.join(funcindir, sub+'_'+ses+'_task-faces_space-MNI152NLin6Asym_desc-preproc_bold.json'),)
param_faces_df = json.load(param_faces_file)

faces_img = nib.load(filefaces)

imageMask = [x for x in flist if ('brain_mask.nii.gz' in x)][0] #'sub-MWMH378_ses-1_task-faces_space-MNI152NLin6Asym_desc-brain_mask.nii.gz'
fileMask = os.path.join(funcindir, imageMask)
mask_img = nib.load(fileMask)

### Specify confounds
confounds_faces_path = os.path.join(funcindir, [x for x in flist if ('task-faces_desc-confounds_timeseries.tsv' in x)][0])
confounds_faces_df = pd.read_csv(confounds_faces_path, sep='\t')

confound_vars = ['trans_x','trans_y','trans_z',
                 'rot_x','rot_y','rot_z', 'global_signal'] #, 'csf', 'white_matter'
deriv_vars = ['{}_derivative1'.format(c) for c
                     in confound_vars]
power_vars = ['{}_power2'.format(c) for c
                     in confound_vars]
power_deriv_vars = ['{}_derivative1_power2'.format(c) for c
                     in confound_vars]
#final_confounds = confound_vars + deriv_vars + power_vars + power_deriv_vars #36, but singular
final_confounds = confound_vars

confounds_faces_df = confounds_faces_df[final_confounds]

### Replace NaNs in confounds df with 0s - NOT CLEAR THAT I SHOULD DO THIS ~~~~~~~~~~~~~~~~~~~~~~~~
confounds_faces_df = confounds_faces_df.fillna(0)


### Transform the events dataframe so that for each unique combination of indicators
### there is a different level of a categorical variable (nilearn seems to require
### a trial_type column)
# https://stackoverflow.com/questions/50607740/reverse-a-get-dummies-encoding-in-pandas

cols = ['blank', 'fix', 'female', 'happy', 'intensity10', 'intensity20',
        'intensity30', 'intensity40', 'intensity50']
#cols2 = ['blank', 'fix', 'female', 'happy']
        #^September 28, 2022: Removed press (attention check where they are supposed to press when they see a face)
for col in cols:
    events_faces_df[col] = events_faces_df[col].map(str)

categ = events_faces_df.apply(lambda x: ''.join(x[cols]),axis=1)
events_categ_faces_df = events_faces_df.iloc[:, 0:2]
events_categ_faces_df['trial_type'] = categ
#categ.unique()

### Fit first level model

#https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.replace.html
#NOTE: Categories may not be exhaustive. Ensure that they are before continuing
#on many subjects
events_categ_faces_df = events_categ_faces_df.replace({'trial_type':
                            {'100000000':'blank', '010000000':'fix',
                            '000010000':'male_angry_intensity10',
                            '000001000':'male_angry_intensity20',
                            '000000100':'male_angry_intensity30',
                            '000000010':'male_angry_intensity40',
                            '000000001':'male_angry_intensity50',
                            '000110000':'male_happy_intensity10',
                            '000101000':'male_happy_intensity20',
                            '000100100':'male_happy_intensity30',
                            '000100010':'male_happy_intensity40',
                            '000100001':'male_happy_intensity50',
                            '001010000':'female_angry_intensity10',
                            '001001000':'female_angry_intensity20',
                            '001000100':'female_angry_intensity30',
                            '001000010':'female_angry_intensity40',
                            '001000001':'female_angry_intensity50',
                            '001110000':'female_happy_intensity10',
                            '001101000':'female_happy_intensity20',
                            '001100100':'female_happy_intensity30',
                            '001100010':'female_happy_intensity40',
                            '001100001':'female_happy_intensity50',
                            }})

# Remove fixation rows
events_categ_faces_df = events_categ_faces_df[~events_categ_faces_df['trial_type'].str.contains('fix')]
events_categ_faces_df = events_categ_faces_df[~events_categ_faces_df['trial_type'].str.contains('blank')]

faces_model = FirstLevelModel(param_faces_df['RepetitionTime'],
                              mask_img=mask_img,
                              noise_model='ar1',
                              standardize=False,
                              hrf_model='spm',
                              drift_model=None,
                              smoothing_fwhm=4)# spm + derivative + dispersion
faces_glm = faces_model.fit(faces_img, events_categ_faces_df, confounds=confounds_faces_df)
#^ Still says singular when take out intensity, derivative and dispersion
#Warning: Matrix is singular at working precision, regularizing... Where is this coming from in the design matrix?
#WHAT IS GOING ON HERE? UserWarning: Mean values of 0 observed. The data have probably been centered. Scaling might not work as expected?
#faces_glm.generate_report() #missing 1 required positional argument: 'contrasts'
design_matrix = faces_model.design_matrices_[0]
plot_design_matrix(design_matrix, output_file=outdir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-faces_design_matrix.pdf')
#^ QUESTION: Why does global signal look constant?
#Not because high mean and low SD - tried scaling and looked the same


#design_matrix_trans = np.transpose(design_matrix)
#eigen_values = np.matmul(design_matrix, design_matrix_trans)




############################### Compute contrasts ##############################

#https://nilearn.github.io/stable/auto_examples/04_glm_first_level/plot_first_level_details.html


### Make contrasts
happy = np.array([])
angry = np.array([])
face = np.array([])
notface = np.array([])

exclude = ['derivative', 'dispersion', 'drift', 'constant', 'trans', 'rot', 'global', 'csf', 'white']
for key in design_matrix.keys():
    if not any(exc in key for exc in exclude):
        if 'happy' in key:
            happy = np.append(happy, 1)
            angry = np.append(angry, 0)
            face = np.append(face, 1)
            notface = np.append(notface, 0)
        elif 'angry' in key:
            angry = np.append(angry, 1)
            happy = np.append(happy, 0)
            face = np.append(face, 1)
            notface = np.append(notface, 0)
        else:
            happy = np.append(happy, 0)
            angry = np.append(angry, 0)
            face = np.append(face, 0)
            notface = np.append(notface, 1)
    else:
        happy = np.append(happy, 0)
        angry = np.append(angry, 0)
        face = np.append(face, 0)
        notface = np.append(notface, 0)


contrasts = {'happy_minus_angry': np.subtract(happy, angry),
            'face_minus_notface': np.subtract(face, notface)}

### Happy minus angry
plot_contrast_matrix(contrasts['happy_minus_angry'], design_matrix=design_matrix,
                        output_file=outdir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-faces_happy_minus_angry_contrast_matrix.pdf')

happy_minus_angry_z_map = faces_model.compute_contrast(
    contrasts['happy_minus_angry'], output_type='z_score')

happy_minus_angry_z_map.to_filename(outdir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-faces_happy_minus_angry_zmap.nii.gz')

plotting.plot_stat_map(happy_minus_angry_z_map, threshold=2.0,
              display_mode='z', cut_coords=3, title='Happy minus angry (Z>2)',
              output_file=outdir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-faces_happy_minus_angry_zmap.pdf')
# TO DO: Unthresholded indicated that the mask may not fit the brain well... vmPFC cut off


### Face minus not face
plot_contrast_matrix(contrasts['face_minus_notface'], design_matrix=design_matrix,
                        output_file=outdir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-faces_face_minus_notface_contrast_matrix.pdf')

face_minus_notface_z_map = faces_model.compute_contrast(
    contrasts['face_minus_notface'], output_type='z_score')

face_minus_notface_z_map.to_filename(outdir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-faces_face_minus_notface_zmap.nii.gz')

plotting.plot_stat_map(face_minus_notface_z_map, threshold=2.0,
              display_mode='z', cut_coords=3, title='Face minus not (Z>2)',
              output_file=outdir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-faces_face_minus_notface_zmap.pdf')










#
