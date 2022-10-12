### Function to calculate fFD based on an FD time series
###
### Ellyn Butler
### September 16, 2022 - October 11, 2022

#https://github.com/GrattonLab/GrattonLab-General-Repo/blob/master/motion_calc_utilities/FDcalc_AFNI.m
#Padding: https://daveboore.com/pubs_online/pads_and_filters_bssa_95_745_750.pdf

from nilearn import signal
import math

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
