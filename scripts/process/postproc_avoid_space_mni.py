### This script conducts the post-processing steps after fmriprep for avoid
###
### Ellyn Butler
### October 19, 2023

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


def postproc_avoid_space_mni(sub, ses, funcindir, bidssesdir, sesoutdir):
    # Location of the pre-processed fMRI & mask
    flist = os.listdir(funcindir)
    file_avoid = os.path.join(funcindir, [x for x in flist if ('space-MNI152NLin6Asym_desc-preproc_bold.nii.gz' in x and 'task-avoid' in x)][0])
    file_avoid_mask = os.path.join(funcindir, [x for x in flist if ('space-MNI152NLin6Asym_desc-brain_mask.nii.gz' in x and 'task-avoid' in x)][0])
    avoid_mask_img = nib.load(file_avoid_mask)

    # Load confounds for rest, avoid and faces
    confounds_avoid_path = os.path.join(funcindir, [x for x in flist if ('task-avoid_desc-confounds_timeseries.tsv' in x)][0])
    confounds_avoid_df = pd.read_csv(confounds_avoid_path, sep='\t')

    # Load task events
    events_avoid_df = pd.read_csv(bidssesdir+'/func/'+sub+'_'+ses+'_task-avoid_events.tsv', sep='\t')

    # Load parameters for rest, avoid and faces
    param_avoid_file = open(os.path.join(funcindir, sub+'_'+ses+'_task-avoid_space-MNI152NLin6Asym_desc-preproc_bold.json'),)
    param_avoid_df = json.load(param_avoid_file)

    # Get TRs
    avoid_tr = param_avoid_df['RepetitionTime']

    #### Select confound columns
    # https://www.sciencedirect.com/science/article/pii/S1053811917302288
    # Removed csf and white_matter because too collinear with global_signal
    confound_vars = ['trans_x','trans_y','trans_z',
                     'rot_x','rot_y','rot_z', 'global_signal'] #, 'csf', 'white_matter'
    deriv_vars = ['{}_derivative1'.format(c) for c in confound_vars]
    power_vars = ['{}_power2'.format(c) for c in confound_vars]
    power_deriv_vars = ['{}_derivative1_power2'.format(c) for c in confound_vars]
    final_confounds = confound_vars + deriv_vars + power_vars + power_deriv_vars

    confounds_avoid_df = confounds_avoid_df.fillna(0)

    avoid_img = nib.load(file_avoid)

    ##### Run task models and obtain residuals
    # https://nilearn.github.io/dev/modules/generated/nilearn.glm.first_level.FirstLevelModel.html
    # https://nilearn.github.io/dev/auto_examples/00_tutorials/plot_single_subject_single_run.html#sphx-glr-auto-examples-00-tutorials-plot-single-subject-single-run-py

    ### avoid
    cols = ['fix1', 'fix2', 'approach', 'avoid', 'nothing', 'gain50', 'gain10',
           'lose10', 'lose50']
    for col in cols:
        events_avoid_df[col] = events_avoid_df[col].map(str)

    categ = events_avoid_df.apply(lambda x: ''.join(x[cols]),axis=1)
    events_categ_avoid_df = events_avoid_df.iloc[:, 0:2]
    events_categ_avoid_df['trial_type'] = categ
    #categ.unique()

    #https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.replace.html
    events_categ_avoid_df = events_categ_avoid_df.replace({'trial_type': {'000100000':'avoid',
                                '100000000':'fix1', '000010000':'nothing',
                                '000000100':'gain10', '010000000':'fix2',
                                '001000000':'approach', '000000010':'lose10',
                                '000001000':'gain50', '000000001':'lose50'}})

    # Remove fixation rows
    events_categ_avoid_df = events_categ_avoid_df[~events_categ_avoid_df['trial_type'].str.contains('fix2')]
    events_categ_avoid_df = events_categ_avoid_df[~events_categ_avoid_df['trial_type'].str.contains('blank')]

    avoid_model = FirstLevelModel(param_avoid_df['RepetitionTime'],
                                  mask_img=avoid_mask_img,
                                  noise_model='ar1',
                                  standardize=False,
                                  hrf_model='spm + derivative + dispersion',
                                  drift_model='cosine',
                                  minimize_memory=False)
    avoid_glm = avoid_model.fit(avoid_img, events_categ_avoid_df)
    avoid_res = avoid_glm.residuals[0]

    ##### Demean and detrend
    avoid_de = image.clean_img(avoid_res, detrend=True, standardize=False, t_r=avoid_tr)

    ##### Nuisance regression
    avoid_reg = image.clean_img(avoid_de, detrend=False, standardize=False,
                            confounds=confounds_avoid_df[final_confounds], t_r=avoid_tr)

    ##### Identify TRs to censor
    confounds_avoid_df = calc_ffd(confounds_avoid_df, avoid_tr)
    confounds_avoid_df['ffd_good'] = confounds_avoid_df['ffd'] < 0.1

    ##### Censor the TRs where fFD > .1
    avoid_cen, confounds_avoid_df = remove_trs(avoid_reg, confounds_avoid_df, replace=False)

    ##### Interpolate over these TRs
    avoid_int = cubic_interp(avoid_cen, avoid_mask_img, avoid_tr, confounds_avoid_df)

    ##### Temporal bandpass filtering + Nuisance regression again
    avoid_band = image.clean_img(avoid_int, detrend=False, standardize=False, t_r=avoid_tr,
                            confounds=confounds_avoid_df[final_confounds],
                            low_pass=0.08, high_pass=0.009)

    ##### Censor volumes identified as having fFD > .1
    avoid_cen2, confounds_avoid_df = remove_trs(avoid_band, confounds_avoid_df, replace=False)
    avoid_cen2.to_filename(sesoutdir+'/'+sub+'_'+ses+'_space-MNI152NLin6Asym_task-avoid_final.nii.gz')

    ##### Quality Metrics
    subid = sub.split('-')[1]
    sesid = ses.split('-')[1]

    avoid_qual_df = get_qual_metrics(confounds_avoid_df, 'avoid', subid, sesid)
    avoid_qual_df.to_csv(sesoutdir+'/'+sub+'_'+ses+'_space-MNI152NLin6Asym_task-avoid_quality.csv', index=False)
