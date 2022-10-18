### This script defines a function to run cubic interpolation over every voxel
### in a nifti image
### https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.lombscargle.html
### https://docs.scipy.org/doc/scipy/tutorial/interpolate.html
###
### Ellyn Butler
### October 12, 2022 - October 18, 2022

#rest_int = power_interp(rest_cen, mask_img, rest_tr)
from scipy.interpolate import interp1d
import numpy as np
import nibabel as nib
#from copy import deepcopy

#img_cen = rest_cen
#mask = rest_mask_img
#tr = rest_tr
#confounds_df = confounds_rest_df

def cubic_interp(img_cen, mask, tr, confounds_df):
    # Get the times that all of the TRs were collected
    all_sample_times = np.arange(confounds_df.shape[0])*tr
    keep_ffd = confounds_df['keep_ffd'].tolist()
    retained_sample_times = all_sample_times[keep_ffd]
    ditch_ffd = [not elem for elem in keep_ffd]
    excluded_sample_times = all_sample_times[ditch_ffd]
    # Turn the nifti into an array object
    img_array = img_cen.get_fdata()
    # Get the voxels that are brain tissue
    mask_array = mask.get_fdata()
    # Make an empty numpy array to put the interpolated data into
    int_array = np.zeros((img_array.shape[0], img_array.shape[1], img_array.shape[2], nout))
    # Loop over the voxels to pull out single times series
    for i in range(img_array.shape[0]):
        for j in range(img_array.shape[1]):
            for k in range(img_array.shape[2]):
                if mask_array[i, j, k]:
                    vals = img_array[i, j, k, :]
                    # Fit the cubic model
                    fit = interp1d(retained_sample_times, vals, kind='cubic')
                    # Get the predicted values for the censored times
                    interp_vals = fit(excluded_sample_times)
                    # Put predicted values in the correct TRs
                    int_array[i, j, k, ditch_ffd] = interp_vals
                    # Put in the retained values
                    int_array[i, j, k, keep_ffd] = vals
    img_int = nib.Nifti1Image(int_array, affine=img_cen.affine)
    return img_int

#https://numpy.org/doc/stable/reference/generated/numpy.nditer.html
# ^ will possibly speed up things in the future