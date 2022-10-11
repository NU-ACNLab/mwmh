### Function to calculate fFD based on an FD time series
###
### Ellyn Butler
### September 16, 2022 - October 11, 2022

#https://github.com/GrattonLab/GrattonLab-General-Repo/blob/master/motion_calc_utilities/FDcalc_AFNI.m
#Padding: https://daveboore.com/pubs_online/pads_and_filters_bssa_95_745_750.pdf

from nilearn import signal
import math

confounds_avoid_path = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep/sub-MWMH270/ses-2/func/sub-MWMH270_ses-2_task-avoid_desc-confounds_timeseries.tsv'
confounds_avoid_df = pd.read_csv(confounds_avoid_path, sep='\t')
confounds_df = confounds_avoid_df

param_avoid_file = open('/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep/sub-MWMH270/ses-2/func/sub-MWMH270_ses-2_task-avoid_space-MNI152NLin6Asym_desc-preproc_bold.json')
param_avoid_df = json.load(param_avoid_file)
tr = param_avoid_df['RepetitionTime']

confounds_df = calc_ffd(confounds_df, tr)

def calc_ffd(confounds_df, tr):
    confounds_df['trans_x_filt'] = signal.butterworth(confounds_df['trans_x'], tr, low_pass=0.1)
    confounds_df['trans_y_filt'] = signal.butterworth(confounds_df['trans_y'], tr, low_pass=0.1)
    confounds_df['trans_z_filt'] = signal.butterworth(confounds_df['trans_z'], tr, low_pass=0.1)
    confounds_df['rot2_x_filt'] = signal.butterworth((confounds_df['rot_x']*50*math.pi)/360, tr, low_pass=0.1)
    confounds_df['rot2_y_filt'] = signal.butterworth((confounds_df['rot_x']*50*math.pi)/360, tr, low_pass=0.1)
    confounds_df['rot2_z_filt'] = signal.butterworth((confounds_df['rot_x']*50*math.pi)/360, tr, low_pass=0.1)
    confounds_df['ffd'] = 0
    for i, row in confounds_df.iterrows():
        if i == 0:
            curr_trans_x_filt = confounds_df.loc[i, 'trans_x_filt']
            curr_trans_y_filt = confounds_df.loc[i, 'trans_y_filt']
            curr_trans_z_filt = confounds_df.loc[i, 'trans_z_filt']
            curr_rot2_x_filt = confounds_df.loc[i, 'rot2_x_filt']
            curr_rot2_y_filt = confounds_df.loc[i, 'rot2_y_filt']
            curr_rot2_z_filt = confounds_df.loc[i, 'rot2_z_filt']
        else:
            prev_trans_x_filt = curr_trans_x_filt
            prev_trans_y_filt = curr_trans_y_filt
            prev_trans_z_filt = curr_trans_z_filt
            prev_rot2_x_filt = curr_rot2_x_filt
            prev_rot2_y_filt = curr_rot2_y_filt
            prev_rot2_z_filt = curr_rot2_z_filt
            curr_trans_x_filt = confounds_df.loc[i, 'trans_x_filt']
            curr_trans_y_filt = confounds_df.loc[i, 'trans_y_filt']
            curr_trans_z_filt = confounds_df.loc[i, 'trans_z_filt']
            curr_rot2_x_filt = confounds_df.loc[i, 'rot2_x_filt']
            curr_rot2_y_filt = confounds_df.loc[i, 'rot2_y_filt']
            curr_rot2_z_filt = confounds_df.loc[i, 'rot2_z_filt']
            confounds_df.loc[i, 'ffd'] = abs(prev_trans_x_filt - curr_trans_x_filt) \
                        + abs(prev_trans_y_filt - curr_trans_y_filt) \
                        + abs(prev_trans_z_filt - curr_trans_z_filt) \
                        + abs(prev_rot2_x_filt - curr_rot2_x_filt) \
                        + abs(prev_rot2_y_filt - curr_rot2_y_filt) \
                        + abs(prev_rot2_z_filt - curr_rot2_z_filt)
    return confounds_df















#
