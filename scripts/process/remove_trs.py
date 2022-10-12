### This script replaces TRs where ffd > .1 with NAs
###
### Ellyn Butler
### October 11, 2022

def remove_trs(img_array, confounds_df, replace=True):
