### This script runs first levels models for the faces task
### https://nilearn.github.io/dev/glm/first_level_model.html
### https://nilearn.github.io/dev/auto_examples/04_glm_first_level/plot_adhd_dmn.html#sphx-glr-auto-examples-04-glm-first-level-plot-adhd-dmn-py
###
### Ellyn Butler
### September 28, 2022

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

#sub = 'sub-MWMH378'
#ses = 'ses-1'
#sub = 'sub-MWMH190'
#ses = 'ses-1'
sub = 'sub-MWMH270'
ses = 'ses-2'

inDir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep/'
subInDir = os.path.join(inDir, sub)
sesInDir = os.path.join(subInDir, ses)
funcInDir = os.path.join(sesInDir, 'func')

outDir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/firstlevel/'
os.makedirs(os.path.join(outDir, sub, ses), exist_ok=True)

bidsDir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/raw/neuroimaging/bids/'

fList = os.listdir(funcInDir)
imagefaces = [x for x in fList if ('preproc_bold.nii.gz' in x and 'task-faces' in x)][0] #'sub-MWMH378_ses-1_task-faces_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz'
filefaces = os.path.join(funcInDir, imagefaces)

bidsSubDir = os.path.join(bidsDir, sub)
bidsSesDir = os.path.join(bidsSubDir, ses)
events_faces_df = pd.read_csv(bidsSesDir+'/func/'+sub+'_'+ses+'_task-faces_events.tsv', sep='\t')

param_faces_file = open(os.path.join(funcInDir, sub+'_'+ses+'_task-faces_space-MNI152NLin6Asym_desc-preproc_bold.json'),)
param_faces_df = json.load(param_faces_file)

faces_img = nib.load(filefaces)

imageMask = [x for x in fList if ('brain_mask.nii.gz' in x)][0] #'sub-MWMH378_ses-1_task-faces_space-MNI152NLin6Asym_desc-brain_mask.nii.gz'
fileMask = os.path.join(funcInDir, imageMask)
mask_img = nib.load(fileMask)

#n_scans = faces_img.shape[3]
#t_r = param_faces_df['RepetitionTime']
#frame_times = np.linspace(0, (n_scans - 1) * t_r, n_scans)

### Transform the events dataframe so that for each unique combination of indicators
### there is a different level of a categorical variable (nilearn seems to require
### a trial_type column)
# https://stackoverflow.com/questions/50607740/reverse-a-get-dummies-encoding-in-pandas

cols = ['blank', 'fix', 'female', 'happy', 'intensity10', 'intensity20',
        'intensity30', 'intensity40', 'intensity50', 'press']
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
                            {'0000001001':'male_angry_intensity30_press',
                            '1000000000':'blank', '0100000000':'fix',
                            '0001000101':'male_happy_intensity40_press',
                            '0011000011':'female_happy_intensity50_press',
                            '0001001001':'male_happy_intensity30_press',
                            '0001010001':'male_happy_intensity20_press',
                            '0010000011':'female_angry_intensity50_press',
                            '0011001001':'female_happy_intensity30_press',
                            '0011100001':'female_happy_intensity10_press',
                            '0011010001':'female_happy_intensity20_press',
                            '0000010001':'male_angry_intensity20_press',
                            '0000100001':'male_angry_intensity10_press',
                            '0010001001':'female_angry_intensity30_press',
                            '0001000011':'male_happy_intensity50_press',
                            '0010000101':'female_angry_intensity40_press',
                            '0001100001':'male_happy_intensity10_press',
                            '0000000101':'male_angry_intensity40_press',
                            '0000000011':'male_angry_intensity50_press',
                            '0010100001':'female_angry_intensity10_press',
                            '0011000101':'female_happy_intensity40_press',
                            '0010010001':'female_angry_intensity20_press'}})

faces_model = FirstLevelModel(param_faces_df['RepetitionTime'],
                              mask_img=mask_img,
                              noise_model='ar1',
                              standardize=False,
                              hrf_model='spm + derivative + dispersion',
                              drift_model='cosine')
faces_glm = faces_model.fit(faces_img, events_categ_faces_df)
#WHAT IS GOING ON HERE? UserWarning: Mean values of 0 observed.The data have probably been centered.Scaling might not work as expected?
#faces_glm.generate_report() #missing 1 required positional argument: 'contrasts'
design_matrix = faces_model.design_matrices_[0]
plot_design_matrix(design_matrix, output_file=outDir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-faces_design_matrix.pdf')

#design_matrices = make_first_level_design_matrix(frame_times, events,
#                          drift_model='polynomial', drift_order=3)

############################### Compute contrasts ##############################

#https://nilearn.github.io/stable/auto_examples/04_glm_first_level/plot_first_level_details.html


### Make contrasts
happy = np.array([])
angry = np.array([])
face = np.array([])
notface = np.array([])
for key in design_matrix.keys():
    if 'derivative' not in key and 'dispersion' not in key and 'drift' not in key and 'constant' not in key:
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
                        output_file=outDir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-faces_happy_minus_angry_contrast_matrix.pdf')

happy_minus_angry_z_map = faces_model.compute_contrast(
    contrasts['happy_minus_angry'], output_type='z_score')

plotting.plot_stat_map(happy_minus_angry_z_map, threshold=3.0,
              display_mode='z', cut_coords=3, title='Happy minus angry (Z>3)',
              output_file=outDir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-faces_happy_minus_angry_zmap.pdf')
# TO DO: Unthresholded indicated that the mask may not fit the brain well... vmPFC cut off


### Face minus not face
plot_contrast_matrix(contrasts['face_minus_notface'], design_matrix=design_matrix,
                        output_file=outDir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-faces_face_minus_notface_contrast_matrix.pdf')

face_minus_notface_z_map = faces_model.compute_contrast(
    contrasts['face_minus_notface'], output_type='z_score')

plotting.plot_stat_map(face_minus_notface_z_map, threshold=3.0,
              display_mode='z', cut_coords=3, title='Face minus not (Z>3)',
              output_file=outDir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-faces_face_minus_notface_zmap.pdf')










#
