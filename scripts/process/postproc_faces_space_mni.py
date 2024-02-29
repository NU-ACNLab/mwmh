### This script conducts the post-processing steps after fmriprep for faces
###
### Ellyn Butler
### November 22, 2021 - February 27, 2024

# Python version: 3.8.4
import os
import json
import pandas as pd #1.0.5
import nibabel as nib #3.2.1
import numpy as np #1.19.1
#from bids.layout import BIDSLayout #may not be needed
from nilearn.input_data import NiftiLabelsMasker #0.8.1
from nilearn import plotting
from nilearn.glm.first_level import FirstLevelModel
from nilearn import signal
from nilearn import image
import matplotlib.pyplot as plt
import scipy.signal as sgnl
import sys, getopt
from calc_ffd import calc_ffd
from remove_trs import remove_trs
from cubic_interp import cubic_interp
from get_qual_metrics import get_qual_metrics


def postproc_faces_space_mni(sub, ses, funcindir, bidssesdir, sesoutdir):
    # Location of the pre-processed fMRI & mask
    flist = os.listdir(funcindir)
    file_faces = os.path.join(funcindir, [x for x in flist if ('space-MNI152NLin6Asym_desc-preproc_bold.nii.gz' in x and 'task-faces' in x)][0])
    file_faces_mask = os.path.join(funcindir, [x for x in flist if ('space-MNI152NLin6Asym_desc-brain_mask.nii.gz' in x and 'task-faces' in x)][0])
    faces_mask_img = nib.load(file_faces_mask)

    # Load confounds for rest, avoid and faces
    confounds_faces_path = os.path.join(funcindir, [x for x in flist if ('task-faces_desc-confounds_timeseries.tsv' in x)][0])
    confounds_faces_df = pd.read_csv(confounds_faces_path, sep='\t')

    # Load task events for faces
    events_faces_df = pd.read_csv(bidssesdir+'/func/'+sub+'_'+ses+'_task-faces_events.tsv', sep='\t')

    # Load parameters for faces
    param_faces_file = open(os.path.join(funcindir, sub+'_'+ses+'_task-faces_space-MNI152NLin6Asym_desc-preproc_bold.json'),)
    param_faces_df = json.load(param_faces_file)

    # Get TRs
    faces_tr = param_faces_df['RepetitionTime']

    #### Select confound columns
    # https://www.sciencedirect.com/science/article/pii/S1053811917302288
    # Removed csf and white_matter because too collinear with global_signal
    confound_vars = ['trans_x','trans_y','trans_z',
                     'rot_x','rot_y','rot_z', 'global_signal'] #, 'csf', 'white_matter'
    deriv_vars = ['{}_derivative1'.format(c) for c in confound_vars]
    power_vars = ['{}_power2'.format(c) for c in confound_vars]
    power_deriv_vars = ['{}_derivative1_power2'.format(c) for c in confound_vars]
    final_confounds = confound_vars + deriv_vars + power_vars + power_deriv_vars

    confounds_faces_df = confounds_faces_df.fillna(0)

    faces_img = nib.load(file_faces)

    ##### Run task models and obtain residuals
    # https://nilearn.github.io/dev/modules/generated/nilearn.glm.first_level.FirstLevelModel.html
    # https://nilearn.github.io/dev/auto_examples/00_tutorials/plot_single_subject_single_run.html#sphx-glr-auto-examples-00-tutorials-plot-single-subject-single-run-py

    ### faces
    cols = ['blank', 'fix', 'female', 'happy', 'intensity10', 'intensity20',
            'intensity30', 'intensity40', 'intensity50']
            #^September 28, 2022: Removed press (attention check where they are supposed to press when they see a face)
    for col in cols:
        events_faces_df[col] = events_faces_df[col].map(str)

    categ = events_faces_df.apply(lambda x: ''.join(x[cols]),axis=1)
    events_categ_faces_df = events_faces_df.iloc[:, 0:2]
    events_categ_faces_df['trial_type'] = categ

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
                                  mask_img=faces_mask_img,
                                  noise_model='ar1',
                                  standardize=False,
                                  hrf_model='spm + derivative + dispersion',
                                  drift_model='cosine',
                                  minimize_memory=False)
    faces_glm = faces_model.fit(faces_img, events_categ_faces_df)
    faces_res = faces_glm.residuals[0]

    ##### Demean and detrend
    faces_de = image.clean_img(faces_res, detrend=True, standardize=False, t_r=faces_tr)

    ##### Nuisance regression
    faces_reg = image.clean_img(faces_de, detrend=False, standardize=False,
                            confounds=confounds_faces_df[final_confounds], t_r=faces_tr)

    ##### Identify TRs to censor
    confounds_faces_df = calc_ffd(confounds_faces_df, faces_tr)
    confounds_faces_df['ffd_good'] = confounds_faces_df['ffd'] < 0.1

    ##### Censor the TRs where fFD > .1
    faces_cen, confounds_faces_df = remove_trs(faces_reg, confounds_faces_df, replace=False)

    ##### Interpolate over these TRs
    faces_int = cubic_interp(faces_cen, faces_mask_img, faces_tr, confounds_faces_df)

    ##### Temporal bandpass filtering + Nuisance regression again
    faces_band = image.clean_img(faces_int, detrend=False, standardize=False, t_r=faces_tr,
                            confounds=confounds_faces_df[final_confounds],
                            low_pass=0.08, high_pass=0.009)

    ##### Censor volumes identified as having fFD > .1
    faces_cen2, confounds_faces_df = remove_trs(faces_band, confounds_faces_df, replace=False)
    faces_cen2.to_filename(sesoutdir+'/'+sub+'_'+ses+'_task-faces_space-MNI152NLin6Asym_desc-postproc_bold.nii.gz')

    ##### Quality Metrics
    subid = sub.split('-')[1]
    sesid = ses.split('-')[1]

    faces_qual_df = get_qual_metrics(confounds_faces_df, 'faces', subid, sesid)
    faces_qual_df.to_csv(sesoutdir+'/'+sub+'_'+ses+'_task-faces_space-MNI152NLin6Asym_quality.csv', index=False)
