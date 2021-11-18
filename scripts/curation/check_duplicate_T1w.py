### This script checks if the duplicate T1w images in the BIDS curation performed
### by Zach are identical.
###
### Ellyn Butler
### November 18, 2021

#import os
import glob
import numpy as np
import nibabel as nib
import pandas as pd

baseDir = '/projects/b1108/data/MWMH/'
bidsDir = baseDir+'bids_directory/'

final_dict = {'subid':[], 'sesid':[], 'numT1w':[], 'filesIdentical':[]}

subDirs = glob.glob(bidsDir + "sub-*")

for subDir in subDirs:
    subid = subDir.split('/')[6].split('-')[1]
    sesDirs = glob.glob(subDir + "/ses-*")
    for sesDir in sesDirs:
        t1wimages = glob.glob(sesDir + "/anat/*T1w.nii.gz")
        sesid = sesDir.split('/')[7].split('-')[1]
        numT1w = len(t1wimages)
        final_dict['subid'].append(subid)
        final_dict['sesid'].append(sesid)
        final_dict['numT1w'].append(numT1w) #weird
        if numT1w > 1:
            firstT1w = t1wimages[0]
            firstT1w_img = nib.load(firstT1w)
            firstT1w_array = firstT1w_img.get_fdata()
            for otherT1w in t1wimages[1:len(t1wimages)]:
                otherT1w_img = nib.load(otherT1w)
                otherT1w_array = otherT1w_img.get_fdata()
                filesId = np.array_equal(firstT1w_array, otherT1w_array)
                if filesId:
                    break
            final_dict['filesIdentical'].append(filesId)

final_df = pd.DataFrame.from_dict(final_dict)

final_df.to_csv(baseDir+'demographics/duplicate_T1w.csv', index=False)
