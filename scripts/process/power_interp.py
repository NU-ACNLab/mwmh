### This script defines a function to run power spectral interpolation over every
### voxel in a nifti image
### https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.lombscargle.html
###
### Ellyn Butler
### October 12, 2022 - October 18, 2022

#rest_int = power_interp(rest_cen, mask_img, rest_tr)
import scipy.signal as sgnl

img_cen = rest_cen
mask = rest_mask_img
tr = rest_tr
confounds_df = confounds_rest_df

def power_interp(img_cen, mask, tr, confounds_df):
    # Turn the nifti into an array object
    img_array = img_cen.get_fdata()
    # Get out many TRs you want out (the number you started with prior to deletion)
    nout = confounds_df.shape[0]
    # Get the times that the retained TRs were collected
    sample_times = np.arange(confounds_df.shape[0])*tr
    sample_times = sample_times[confounds_df['keep_ffd'].tolist()]
    # Get the frequencies over which you want to compute the periodogram
    freqs = np.linspace(0.01, 10, nout)
    # Get the voxels that are brain tissue
    mask_array = mask.get_fdata()
    # Loop over the voxels to pull out single times series
    for i in range(img_array.shape[0]):
        for j in range(img_array.shape[1]):
            for k in range(img_array.shape[2]):
                if mask_array[i, j, k]:
                    vals = img_array[i, j, k, :]
                    pgram = sgnl.lombscargle(sample_times, vals, freqs, normalize=False)

#https://numpy.org/doc/stable/reference/generated/numpy.nditer.html
# ^ will possibly speed up things in the future


i=50
j=50
k=50
