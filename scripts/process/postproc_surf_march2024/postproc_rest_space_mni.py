### This script conducts the post-processing steps after fmriprep for rest
###
### Ellyn Butler
### November 22, 2021 - October 19, 2022

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
import scipy.signal as sgnl #1.5.4
import sys, getopt
from calc_ffd import calc_ffd
from remove_trs import remove_trs
from cubic_interp import cubic_interp


def postproc_rest_space_mni(sub, ses, funcindir, bidssesdir, sesoutdir):
    # Location of the pre-processed fMRI & mask
    flist = os.listdir(funcindir)
    file_rest = os.path.join(funcindir, [x for x in flist if ('space-MNI152NLin6Asym_desc-preproc_bold.nii.gz' in x and 'task-rest' in x)][0])
    file_rest_mask = os.path.join(funcindir, [x for x in flist if ('space-MNI152NLin6Asym_desc-brain_mask.nii.gz' in x and 'task-rest' in x)][0])
    rest_mask_img = nib.load(file_rest_mask)

    # Load confounds for rest, avoid and faces
    confounds_rest_path = os.path.join(funcindir, [x for x in flist if ('task-rest_desc-confounds_timeseries.tsv' in x)][0])
    confounds_rest_df = pd.read_csv(confounds_rest_path, sep='\t')

    # Load parameters for rest, avoid and faces
    param_rest_file = open(os.path.join(funcindir, sub+'_'+ses+'_task-rest_space-MNI152NLin6Asym_desc-preproc_bold.json'),)
    param_rest_df = json.load(param_rest_file)

    # Get TRs
    rest_tr = param_rest_df['RepetitionTime']

    #### Select confound columns
    # https://www.sciencedirect.com/science/article/pii/S1053811917302288
    # Removed csf and white_matter because too collinear with global_signal
    confound_vars = ['trans_x','trans_y','trans_z',
                     'rot_x','rot_y','rot_z', 'global_signal'] #, 'csf', 'white_matter'
    deriv_vars = ['{}_derivative1'.format(c) for c in confound_vars]
    power_vars = ['{}_power2'.format(c) for c in confound_vars]
    power_deriv_vars = ['{}_derivative1_power2'.format(c) for c in confound_vars]
    final_confounds = confound_vars + deriv_vars + power_vars + power_deriv_vars

    confounds_rest_df = confounds_rest_df.fillna(0)

    rest_img = nib.load(file_rest)

    ##### Demean and detrend
    rest_de = image.clean_img(rest_img, detrend=True, standardize=False, t_r=rest_tr)

    ##### Nuisance regression
    rest_reg = image.clean_img(rest_de, detrend=False, standardize=False,
                            confounds=confounds_rest_df[final_confounds], t_r=rest_tr)

    ###### Identify TRs to censor
    confounds_rest_df = calc_ffd(confounds_rest_df, rest_tr)
    confounds_rest_df['ffd_good'] = confounds_rest_df['ffd'] < 0.1

    ##### Censor the TRs where fFD > .1
    rest_cen, confounds_rest_df = remove_trs(rest_reg, confounds_rest_df, replace=False)

    ##### Interpolate over these TRs
    rest_int = cubic_interp(rest_cen, rest_mask_img, rest_tr, confounds_rest_df)

    ##### Temporal bandpass filtering + Nuisance regression again
    rest_band = image.clean_img(rest_int, detrend=False, standardize=False, t_r=rest_tr,
                            confounds=confounds_rest_df[final_confounds],
                            low_pass=0.08, high_pass=0.009)

    ##### Censor volumes identified as having fFD > .1
    rest_cen2, confounds_rest_df = remove_trs(rest_band, confounds_rest_df, replace=False)
    rest_cen2.to_filename(sesoutdir+'/'+sub+'_'+ses+'_task-rest_space-MNI152NLin6Asym_desc-postproc_bold.nii.gz')

    ##### Quality Metrics
    subid = sub.split('-')[1]
    sesid = ses.split('-')[1]
