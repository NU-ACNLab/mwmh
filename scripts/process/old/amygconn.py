### This script conducts the post-processing steps after fmriprep
###
### Ellyn Butler
### November 22, 2021 - October 18, 2022

# Python version: 3.8.4
import os
import json
import pandas as pd #1.0.5
import nibabel as nib #3.2.1
import numpy as np #1.19.1
#from bids.layout import BIDSLayout #may not be needed
from nilearn.input_data import NiftiLabelsMasker #0.8.1
from nilearn.connectome import ConnectivityMeasure
from nilearn import plotting
from nilearn.glm.first_level import FirstLevelModel
from nilearn import signal
from nilearn import image
import matplotlib.pyplot as plt
import scipy.signal as sgnl
import sys, getopt
import argparse
from calc_ffd import calc_ffd
from remove_trs import remove_trs
from cubic_interp import cubic_interp
from get_qual_metrics import get_qual_metrics

parser = argparse.ArgumentParser()
parser.add_argument('-i', default='/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep/')
parser.add_argument('-o', default='/projects/b1108/studies/mwmh/data/processed/neuroimaging/amygconn/')
parser.add_argument('-b', default='/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/')
parser.add_argument('-s')
parser.add_argument('-ss')
args = parser.parse_args()

indir = args.i #indir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep/'
outdir = args.o #outdir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/amygconn/'
bidsdir = args.b #bidsdir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/raw/neuroimaging/bids/'
sub = args.s #sub = 'sub-MWMH212'
ses = args.ss #ses = 'ses-2'

# Directory where preprocessed fMRI data is located
subindir = os.path.join(indir, sub)
sesindir = os.path.join(subindir, ses)
funcindir = os.path.join(sesindir, 'func')

# Directory where outputs should go
suboutdir = os.path.join(outdir, sub)
sesoutdir = os.path.join(suboutdir, ses)

# Location of the pre-processed fMRI & mask
flist = os.listdir(funcindir)
file_rest = os.path.join(funcindir, [x for x in flist if ('preproc_bold.nii.gz' in x and 'task-rest' in x)][0])
file_avoid = os.path.join(funcindir, [x for x in flist if ('preproc_bold.nii.gz' in x and 'task-avoid' in x)][0])
file_faces = os.path.join(funcindir, [x for x in flist if ('preproc_bold.nii.gz' in x and 'task-faces' in x)][0])

file_rest_mask = os.path.join(funcindir, [x for x in flist if ('brain_mask.nii.gz' in x and 'task-rest' in x)][0])
file_avoid_mask = os.path.join(funcindir, [x for x in flist if ('brain_mask.nii.gz' in x and 'task-avoid' in x)][0])
file_faces_mask = os.path.join(funcindir, [x for x in flist if ('brain_mask.nii.gz' in x and 'task-faces' in x)][0])

rest_mask_img = nib.load(file_rest_mask)
avoid_mask_img = nib.load(file_avoid_mask)
faces_mask_img = nib.load(file_faces_mask)

# Get the labeled image
seitzdir = '/projects/b1081/Atlases/Seitzman300/' #seitzdir='/Users/flutist4129/Documents/Northwestern/templates/Seitzman300/'
labels_img = nib.load(seitzdir+'Seitzman300_MNI_res02_allROIs.nii.gz')
# ^ Not going to work. Only cortical labels
labels_path = seitzdir+'ROIs_anatomicalLabels.txt'
labels_df = pd.read_csv(labels_path, sep='\t')
labels_df = labels_df.rename(columns={'0=cortexMid,1=cortexL,2=cortexR,3=hippocampus,4=amygdala,5=basalGanglia,6=thalamus,7=cerebellum': 'region'})

labels_list = labels_df.iloc[:, 0] # will want to truncate names

# Load confounds for rest, avoid and faces
confounds_rest_path = os.path.join(funcindir, [x for x in flist if ('task-rest_desc-confounds_timeseries.tsv' in x)][0])
confounds_rest_df = pd.read_csv(confounds_rest_path, sep='\t')
confounds_avoid_path = os.path.join(funcindir, [x for x in flist if ('task-avoid_desc-confounds_timeseries.tsv' in x)][0])
confounds_avoid_df = pd.read_csv(confounds_avoid_path, sep='\t')
confounds_faces_path = os.path.join(funcindir, [x for x in flist if ('task-faces_desc-confounds_timeseries.tsv' in x)][0])
confounds_faces_df = pd.read_csv(confounds_faces_path, sep='\t')
os.makedirs(os.path.join(outdir, sub, ses), exist_ok=True)

# Load task events for avoid and faces
bidssubdir = os.path.join(bidsdir, sub)
bidssesdir = os.path.join(bidssubdir, ses)
events_avoid_df = pd.read_csv(bidssesdir+'/func/'+sub+'_'+ses+'_task-avoid_events.tsv', sep='\t')
events_faces_df = pd.read_csv(bidssesdir+'/func/'+sub+'_'+ses+'_task-faces_events.tsv', sep='\t')

# Load parameters for rest, avoid and faces
param_rest_file = open(os.path.join(funcindir, sub+'_'+ses+'_task-rest_space-MNI152NLin6Asym_desc-preproc_bold.json'),)
param_rest_df = json.load(param_rest_file)
param_avoid_file = open(os.path.join(funcindir, sub+'_'+ses+'_task-avoid_space-MNI152NLin6Asym_desc-preproc_bold.json'),)
param_avoid_df = json.load(param_avoid_file)
param_faces_file = open(os.path.join(funcindir, sub+'_'+ses+'_task-faces_space-MNI152NLin6Asym_desc-preproc_bold.json'),)
param_faces_df = json.load(param_faces_file)

# Get TRs
rest_tr = param_rest_df['RepetitionTime']
avoid_tr = param_avoid_df['RepetitionTime']
faces_tr = param_faces_df['RepetitionTime']

#### Select confound columns
# https://www.sciencedirect.com/science/article/pii/S1053811917302288
# Removed csf and white_matter because too collinear with global_signal
confound_vars = ['trans_x','trans_y','trans_z',
                 'rot_x','rot_y','rot_z', 'global_signal'] #, 'csf', 'white_matter'
deriv_vars = ['{}_derivative1'.format(c) for c
                     in confound_vars]
power_vars = ['{}_power2'.format(c) for c
                     in confound_vars]
power_deriv_vars = ['{}_derivative1_power2'.format(c) for c
                     in confound_vars]
final_confounds = confound_vars + deriv_vars + power_vars + power_deriv_vars

## REST
#confounds_rest_df = confounds_rest_df.loc[5:] # drop the first 5 TRs from confounds df
confounds_rest_df = confounds_rest_df.fillna(0)

## AVOID (onset: 12)
#confounds_avoid_df = confounds_avoid_df.loc[6:] # drop the first 6 TRs from confounds df
confounds_avoid_df = confounds_avoid_df.fillna(0)
# subtract off 6 TRs*RT 2 = 12 from the onset column
#events_avoid_df['onset'] = events_avoid_df['onset'] - 12

## FACES (onset: 14.5)
#confounds_faces_df = confounds_faces_df.loc[5:] # drop the first 5 TRs from confounds df
confounds_faces_df = confounds_faces_df.fillna(0)
# subtract off 5 TRs*RT 2 = 10 from the onset column
#events_faces_df['onset'] = events_faces_df['onset'] - 10

#### Remove first X TRs (September 20, 2022: Stop doing this)
#https://carpentries-incubator.github.io/SDC-BIDS-fMRI/05-data-cleaning-with-nilearn/index.html
# REST: Remove first 5 TRs
rest_img = nib.load(file_rest)
#rest_img = raw_rest_img.slicer[:,:,:,5:]

# AVOID: Remove first 6 TRs
avoid_img = nib.load(file_avoid)
#avoid_img = raw_avoid_img.slicer[:,:,:,6:]

# FACES: Remove first 5 TRs
faces_img = nib.load(file_faces)
#faces_img = raw_faces_img.slicer[:,:,:,5:]


##################### Run task models and obtain residuals #####################
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
                            '100000000':'fix1', '000000100':'gain10',
                            '010000000':'fix2', '001000000':'approach',
                            '000000010':'lose10', '000001000':'gain50',
                            '000000001':'lose50'}})

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

### faces
cols = ['blank', 'fix', 'female', 'happy', 'intensity10', 'intensity20',
        'intensity30', 'intensity40', 'intensity50']
        #^September 28, 2022: Removed press (attention check where they are supposed to press when they see a face)
for col in cols:
    events_faces_df[col] = events_faces_df[col].map(str)

categ = events_faces_df.apply(lambda x: ''.join(x[cols]),axis=1)
events_categ_faces_df = events_faces_df.iloc[:, 0:2]
events_categ_faces_df['trial_type'] = categ

events_categ_faces_df = events_categ_faces_df.replace({'trial_type':
                            {'100000000':'blank', '010000000':'fix',
                            '000010000':'male_angry_intensity10',
                            '000001000':'male_angry_intensity20',
                            '000000100':'male_angry_intensity30',
                            '000000010':'male_angry_intensity40',
                            '000000001':'male_angry_intensity50',
                            '000110000':'male_happy_intensity10',
                            '000101000':'male_happy_intensity20',
                            '000100100':'male_happy_intensity30',
                            '000100010':'male_happy_intensity40',
                            '000100001':'male_happy_intensity50',
                            '001010000':'female_angry_intensity10',
                            '001001000':'female_angry_intensity20',
                            '001000100':'female_angry_intensity30',
                            '001000010':'female_angry_intensity40',
                            '001000001':'female_angry_intensity50',
                            '001110000':'female_happy_intensity10',
                            '001101000':'female_happy_intensity20',
                            '001100100':'female_happy_intensity30',
                            '001100010':'female_happy_intensity40',
                            '001100001':'female_happy_intensity50',
                            }})

# Remove fixation rows
events_categ_faces_df = events_categ_faces_df[~events_categ_faces_df['trial_type'].str.contains('fix')]
events_categ_faces_df = events_categ_faces_df[~events_categ_faces_df['trial_type'].str.contains('blank')]

faces_model = FirstLevelModel(param_faces_df['RepetitionTime'],
                              mask_img=faces_mask_img,
                              noise_model='ar1',
                              standardize=False,
                              hrf_model='spm + derivative + dispersion',
                              drift_model='cosine',
                              minimize_memory=False)
faces_glm = faces_model.fit(faces_img, events_categ_faces_df)
faces_res = faces_glm.residuals[0]


############################## Demean and detrend ##############################

#https://carpentries-incubator.github.io/SDC-BIDS-fMRI/05-data-cleaning-with-nilearn/index.html
#https://nilearn.github.io/dev/modules/generated/nilearn.image.clean_img.html

rest_de = image.clean_img(rest_img, detrend=True, standardize=False, t_r=rest_tr)
avoid_de = image.clean_img(avoid_res, detrend=True, standardize=False, t_r=avoid_tr)
faces_de = image.clean_img(faces_res, detrend=True, standardize=False, t_r=faces_tr)


############################# Nuisance regression ##############################

rest_reg = image.clean_img(rest_de, detrend=False, standardize=False,
                        confounds=confounds_rest_df[final_confounds], t_r=rest_tr)
avoid_reg = image.clean_img(avoid_de, detrend=False, standardize=False,
                        confounds=confounds_avoid_df[final_confounds], t_r=avoid_tr)
faces_reg = image.clean_img(faces_de, detrend=False, standardize=False,
                        confounds=confounds_faces_df[final_confounds], t_r=faces_tr)

# Write out images for ease of testing code later
#rest_reg.to_filename(sesoutdir+'/'+sub+'_'+ses+'_task-rest_nuisreg.nii.gz')
#avoid_reg.to_filename(sesoutdir+'/'+sub+'_'+ses+'_task-avoid_nuisreg.nii.gz')
#faces_reg.to_filename(sesoutdir+'/'+sub+'_'+ses+'_task-faces_nuisreg.nii.gz')

#rest_reg = nib.load(sesoutdir+'/'+sub+'_'+ses+'_task-rest_nuisreg.nii.gz')
#avoid_reg = nib.load(sesoutdir+'/'+sub+'_'+ses+'_task-avoid_nuisreg.nii.gz')
#faces_reg = nib.load(sesoutdir+'/'+sub+'_'+ses+'_task-faces_nuisreg.nii.gz')

############################# Identify TRs to censor ###########################
#https://nilearn.github.io/dev/auto_examples/03_connectivity/plot_signal_extraction.html#sphx-glr-auto-examples-03-connectivity-plot-signal-extraction-py
##https://nilearn.github.io/stable/modules/generated/nilearn.interfaces.fmriprep.load_confounds.html

##### Rest
confounds_rest_df = calc_ffd(confounds_rest_df, rest_tr)
confounds_rest_df['ffd_good'] = confounds_rest_df['ffd'] < 0.1

##### Avoid
confounds_avoid_df = calc_ffd(confounds_avoid_df, avoid_tr)
confounds_avoid_df['ffd_good'] = confounds_avoid_df['ffd'] < 0.1

##### Faces
confounds_faces_df = calc_ffd(confounds_faces_df, faces_tr)
confounds_faces_df['ffd_good'] = confounds_faces_df['ffd'] < 0.1


######################### Censor the TRs where fFD > .1 ########################

rest_cen, confounds_rest_df = remove_trs(rest_reg, confounds_rest_df, replace=False)
avoid_cen, confounds_avoid_df = remove_trs(avoid_reg, confounds_avoid_df, replace=False)
faces_cen, confounds_faces_df = remove_trs(faces_reg, confounds_faces_df, replace=False)


########################## Interpolate over these TRs ##########################
#https://pylians3.readthedocs.io/en/master/interpolation.html
#https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.lombscargle.html

rest_int = cubic_interp(rest_cen, rest_mask_img, rest_tr, confounds_rest_df)
avoid_int = cubic_interp(avoid_cen, avoid_mask_img, avoid_tr, confounds_avoid_df)
faces_int = cubic_interp(faces_cen, faces_mask_img, faces_tr, confounds_faces_df)


############ Temporal bandpass filtering + Nuisance regression again ###########

rest_band = image.clean_img(rest_int, detrend=False, standardize=False, t_r=rest_tr,
                        confounds=confounds_rest_df[final_confounds],
                        low_pass=0.08, high_pass=0.009)
avoid_band = image.clean_img(avoid_int, detrend=False, standardize=False, t_r=avoid_tr,
                        confounds=confounds_avoid_df[final_confounds],
                        low_pass=0.08, high_pass=0.009)
faces_band = image.clean_img(faces_int, detrend=False, standardize=False, t_r=faces_tr,
                        confounds=confounds_faces_df[final_confounds],
                        low_pass=0.08, high_pass=0.009)


################# Censor volumes identified as having fFD > .1 #################

rest_cen2, confounds_rest_df = remove_trs(rest_band, confounds_rest_df, replace=False)
avoid_cen2, confounds_avoid_df = remove_trs(avoid_band, confounds_avoid_df, replace=False)
faces_cen2, confounds_faces_df = remove_trs(faces_band, confounds_faces_df, replace=False)

# Write out imgs
rest_cen2.to_filename(sesoutdir+'/'+sub+'_'+ses+'_task-rest_final.nii.gz')
avoid_cen2.to_filename(sesoutdir+'/'+sub+'_'+ses+'_task-avoid_final.nii.gz')
faces_cen2.to_filename(sesoutdir+'/'+sub+'_'+ses+'_task-faces_final.nii.gz')


############################ Run masker on all scans ###########################

masker_rest = NiftiLabelsMasker(labels_img=labels_img,
                            labels=labels_list,
                            mask_img=rest_mask_img,
                            smoothing_fwhm=0,
                            standardize=True,
                            detrend=False,
                            low_pass=None,
                            high_pass=None,
                            verbose=5,
                            t_r=rest_tr
                        )
masker_avoid = NiftiLabelsMasker(labels_img=labels_img,
                            labels=labels_list,
                            mask_img=avoid_mask_img,
                            smoothing_fwhm=0,
                            standardize=True,
                            detrend=False,
                            low_pass=None,
                            high_pass=None,
                            verbose=5,
                            t_r=avoid_tr
                        )
masker_faces = NiftiLabelsMasker(labels_img=labels_img,
                            labels=labels_list,
                            mask_img=faces_mask_img,
                            smoothing_fwhm=0,
                            standardize=True,
                            detrend=False,
                            low_pass=None,
                            high_pass=None,
                            verbose=5,
                            t_r=faces_tr
                        )

rest_time_series = masker_rest.fit_transform(rest_cen2)
avoid_time_series = masker_avoid.fit_transform(avoid_cen2)
faces_time_series = masker_faces.fit_transform(faces_cen2)


################################ Quality Metrics ###############################

subid = sub.split('-')[1]
sesid = ses.split('-')[1]

rest_qual_df = get_qual_metrics(confounds_rest_df, 'rest', subid, sesid)
avoid_qual_df = get_qual_metrics(confounds_avoid_df, 'avoid', subid, sesid)
faces_qual_df = get_qual_metrics(confounds_faces_df, 'faces', subid, sesid)
qual_df = pd.concat([rest_qual_df, avoid_qual_df, faces_qual_df])

qual_df.to_csv(outdir+sub+'/'+ses+'/'+sub+'_'+ses+'_quality.csv', index=False)


################################# Connectivity #################################
# Write out time series
np.savetxt(outdir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-rest_atlas-seitz_timeseries.csv',
    rest_time_series, delimiter=',')
np.savetxt(outdir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-avoid_atlas-seitz_timeseries.csv',
    avoid_time_series, delimiter=',')
np.savetxt(outdir+sub+'/'+ses+'/'+sub+'_'+ses+'_task-faces_atlas-seitz_timeseries.csv',
    faces_time_series, delimiter=',')

#correlation_measure = ConnectivityMeasure(kind='correlation')
#rest_corr_matrix = correlation_measure.fit_transform(rest_time_series)[0]
#avoid_corr_matrix = correlation_measure.fit_transform(avoid_time_series)[0]
#faces_corr_matrix = correlation_measure.fit_transform(faces_time_series)[0]
# ^ no longer working for a single subject

# Correlate every column with every other column
rest_corr_matrix = np.corrcoef(rest_time_series, rowvar=False)
avoid_corr_matrix = np.corrcoef(avoid_time_series, rowvar=False)
faces_corr_matrix = np.corrcoef(faces_time_series, rowvar=False)

# Average correlation matrices... CHECK WORKS
corr_matrix = (rest_corr_matrix + avoid_corr_matrix + faces_corr_matrix)/3

corr_mat_plt = plt.matshow(corr_matrix)
plt.savefig(outdir+sub+'/'+ses+'/'+sub+'_'+ses+'_corrmat.pdf')

# Write out correlation matrix
np.savetxt(outdir+sub+'/'+ses+'/'+sub+'_'+ses+'_atlas-seitz_corrmat.csv',
    corr_matrix, delimiter=',')

##### Write out average amygdala connectivity
# Get amygdalae indices and average connectivity
amyg_indices = labels_df[labels_df['region'] == 4].index
amyg_corr = corr_matrix[amyg_indices]
amyg_ave_corr = (amyg_corr[0,] + amyg_corr[1,])/2 # average across right and left

# Name columns
amyg_cols = ['region'+str(x) for x in range(1,301)]
amyg_df = pd.DataFrame(columns = amyg_cols)
amyg_df.loc[0] = amyg_ave_corr.T
amyg_df['subid'] = subid
amyg_df['sesid'] = sesid
cols = ['subid', 'sesid']
cols.extend(amyg_cols)
amyg_df = amyg_df[cols]

amyg_df.to_csv(outdir+sub+'/'+ses+'/'+sub+'_'+ses+'_atlas-seitz_amygcorr.csv', index=False)








# Generate reports
# `generate_report`: https://nilearn.github.io/dev/modules/generated/nilearn.glm.first_level.FirstLevelModel.html?highlight=fit_transform#nilearn.glm.first_level.FirstLevelModel.fit_transform











# Make a large figure, masking the main diagonal for visualization:
#np.fill_diagonal(correlation_matrix, 0)

# The labels we have start with the background (0), hence we skip the first label.
# matrices are ordered for block-like representation
#https://nilearn.github.io/modules/generated/nilearn.plotting.plot_matrix.html
# TO DO: This isn't working
#plotting.plot_matrix(corr_matrix, figure=(10, 8), labels=amyg_cols,
#                     vmax=0.8, vmin=-0.8, reorder=True,
#                     output_file=outdir+sub+'/'+ses+'/'+sub+'_'+ses+'_corrmat.png')
