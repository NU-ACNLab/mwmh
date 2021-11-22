### This script conducts the post-processing steps after fmriprep
###
### Ellyn Butler
### November 22, 2021

import os
import pandas as pd
import nibabel as nib
from bids.layout import BIDSLayout #may not be needed
from nilearn.input_data import NiftiLabelsMasker
from nilearn.connectome import ConnectivityMeasure
from nilearn import plotting
import sys, getopt

def main(argv):
   inputfile = ''
   outputfile = ''
   try:
      opts, args = getopt.getopt(argv,"hi:o:",["idir=","odir=","sub=","ses="])
   except getopt.GetoptError:
      print 'test.py -i <inputdir> -o <outputdir> -s <subject> -ss <session>'
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
         print 'amygconn.py -i <inputdir> -o <outputdir> -s <subject> -ss <session>'
         sys.exit()
      elif opt in ("-i", "--idir"):
         inDir = arg
      elif opt in ("-o", "--odir"):
         outDir = arg
      elif opt in ("-s", "--sub"):
         subj = arg
      elif opt in ("-ss", "--ses"):
         ses = arg
   print 'Input directory is "', inDir
   print 'Output directory is "', outDir
   print 'Subject is "', subj
   print 'Sesssion is "', ses

##### DIRECTORY BUSINESS ######
# original data directory
inDir = '/projects/b1108/data/MWMH/fmriprep'
# Output directory
outDir = '/projects/b1108/data/MWMH/amygconn'

subj = 'sub-'+'MWMH117' #subj
ses = 'ses-'+'1' #ses


# directory where preprocessed fMRI data is located
subjInDir = os.path.join(inDir, subj)
sesInDir = os.path.join(subjInDir, ses)
funcInDir = os.path.join(sesInDir, 'func')

# location of the pre-processed fMRI & mask
fList = os.listdir(funcInDir)
imagefMRI = [x for x in fList if ('preproc_bold.nii.gz' in x)][0]
imageMask = [x for x in fList if ('brain_mask.nii.gz' in x)][0]

filefMRI = os.path.join(funcInDir, imagefMRI)
fileMask = os.path.join(funcInDir, imageMask)
mask_img = nib.load(fileMask)

MNIDir = '/projects/b1108/templateflow/tpl-MNI152NLin2009cAsym/'
labels_img = nib.load(MNIDir+'tpl-MNI152NLin2009cAsym_res-01_atlas-Schaefer2018_desc-1000Parcels7Networks_dseg.nii.gz')
labels_path = MNIDir+'tpl-MNI152NLin2009cAsym_atlas-Schaefer2018_desc-1000Parcels7Networks_dseg.tsv'
labels_df = pd.read_csv(labels_path, sep='\t')
labels_list = labels_df['name'] # will want to truncate names
confounds_path = os.path.join(funcInDir, [x for x in fList if ('confounds_timeseries.tsv' in x)][0])
confounds_df = pd.read_csv(confounds_path, sep='\t')
confounds_csv = os.path.join(outDir, subj, ses, 'confounds.csv')
os.makedirs(os.path.join(outDir, subj, ses), exist_ok=True)
confounds_df.to_csv(confounds_csv, index=False)



# read docs: detrend, low_pass, high_pass (should depend on TR)
masker = NiftiLabelsMasker(labels_img=labels_img,
                            labels=labels_list,
                            mask_img=mask_img,
                            smoothing_fwhm=6,
                            standardize=True,
                            detrend=True,
                            low_pass=.01,
                            high_pass=.08,
                            verbose=5
                        )

time_series = masker.fit_transform(filefMRI, confounds=confounds_csv)

correlation_measure = ConnectivityMeasure(kind='correlation')
correlation_matrix = correlation_measure.fit_transform([time_series])[0]

# Make a large figure, masking the main diagonal for visualization:
np.fill_diagonal(correlation_matrix, 0)

# The labels we have start with the background (0), hence we skip the first label.
# matrices are ordered for block-like representation
plotting.plot_matrix(correlation_matrix, figure=(10, 8), labels=labels[1:],
                     vmax=0.8, vmin=-0.8, reorder=True)