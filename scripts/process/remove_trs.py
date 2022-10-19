### This script replaces TRs where ffd > .1 with NAs
###
### Ellyn Butler
### October 11, 2022 - October 13, 2022

#https://stackoverflow.com/questions/60208043/how-to-replace-the-first-dimension-of-a-3d-numpy-array-with-values-from-a-1d-arr
import nibabel as nib #3.2.1
import numpy as np #1.19.1

def remove_trs(img, confounds_df, replace=True):
    img_array = img.get_fdata()
    if 'keep_ffd' not in confounds_df.columns:
        keep_array = np.full((img_array.shape[3]), True)
        for index, row in confounds_df.iterrows():
            keep = confounds_df.loc[index, 'ffd_good']
            if keep == False:
                np.put(keep_array, index, False)
                # Is there a False within the subsequent 6?
                nextsix = confounds_df.loc[(index+1):(index+6), 'ffd_good'].to_list()
                if len(nextsix) > 0:
                    if nextsix[0] == True and (False in nextsix or len(nextsix) < 6):
                        # If so, replace all the intervening Trues with False
                        index_firstfalse = index + nextsix.index(False) + 1
                        np.put(keep_array, range(index, index_firstfalse), False)
                        #keep_array[index:index_firstfalse] = False
        confounds_df['keep_ffd'] = keep_array
    else:
        keep_array = confounds_df['keep_ffd'].to_list()
    # NA out bad TRs
    if replace == True:
        for i in range(0, img.shape[3]):
            if keep_array[i] == False:
                img_array[:,:,:,i] = float('nan')
    else:
        img_array = img_array[:,:,:,keep_array]
    img_cen = nib.Nifti1Image(img_array, affine=img.affine)
    return img_cen, confounds_df
