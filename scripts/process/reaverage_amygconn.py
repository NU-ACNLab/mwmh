### This script reaverages the correlation matrices based on which tasks
### have enough data (> 5 minutes) after applying exclusions determined by the
### fFD cutoff.
###
### Ellyn Butler
### October 31, 2022

import os
import json
import pandas as pd #1.0.5
import nibabel as nib #3.2.1

parser = argparse.ArgumentParser()
parser.add_argument('-i', default='/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep/')
parser.add_argument('-o', default='/projects/b1108/studies/mwmh/data/processed/neuroimaging/amygconn/')
parser.add_argument('-b', default='/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/')
parser.add_argument('-s')
parser.add_argument('-ss')
parser.add_argument('-t', nargs='+') #https://www.codegrepper.com/code-examples/python/python+argparse+multiple+values
args = parser.parse_args()

indir = args.i #indir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep/'
outdir = args.o #outdir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/amygconn/'
bidsdir = args.b #bidsdir = '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/raw/neuroimaging/bids/'
sub = args.s #sub = 'sub-MWMH359'
ses = args.ss #ses = 'ses-1'
tasks = args.t

# Directory where preprocessed fMRI data is located
subindir = os.path.join(indir, sub)
sesindir = os.path.join(subindir, ses)
funcindir = os.path.join(sesindir, 'func')

# Directory where outputs should go
suboutdir = os.path.join(outdir, sub)
sesoutdir = os.path.join(suboutdir, ses)

# Get the bids directory for this session
bidssubdir = os.path.join(bidsdir, sub)
bidssesdir = os.path.join(bidssubdir, ses)

# Get the labeled image and labels
seitzdir = '/projects/b1081/Atlases/Seitzman300/' #seitzdir='/Users/flutist4129/Documents/Northwestern/templates/Seitzman300/'
labels_img = nib.load(seitzdir+'Seitzman300_MNI_res02_allROIs.nii.gz')
labels_path = seitzdir+'ROIs_anatomicalLabels.txt'
labels_df = pd.read_csv(labels_path, sep='\t')
labels_df = labels_df.rename(columns={'0=cortexMid,1=cortexL,2=cortexR,3=hippocampus,4=amygdala,5=basalGanglia,6=thalamus,7=cerebellum': 'region'})
labels_list = labels_df.iloc[:, 0]


############################## Load available tasks ############################

if 'rest' in tasks:
    rest_time_series = np.loadtxt(sesoutdir+'/'+sub+'_'+ses+'_task-rest_atlas-seitz_timeseries.csv', delimiter=',')
    rest_corr_matrix = np.corrcoef(rest_time_series, rowvar=False)
if 'avoid' in tasks:
    avoid_time_series = np.loadtxt(sesoutdir+'/'+sub+'_'+ses+'_task-avoid_atlas-seitz_timeseries.csv', delimiter=',')
    avoid_corr_matrix = np.corrcoef(avoid_time_series, rowvar=False)
if 'faces' in tasks:
    faces_time_series = np.loadtxt(sesoutdir+'/'+sub+'_'+ses+'_task-faces_atlas-seitz_timeseries.csv', delimiter=',')
    faces_corr_matrix = np.corrcoef(faces_time_series, rowvar=False)

################################# Combine tasks ################################

if 'rest' in tasks and 'avoid' in tasks and 'faces' in tasks:
    corr_matrix = (rest_corr_matrix + avoid_corr_matrix + faces_corr_matrix)/3
elif 'rest' in tasks and 'avoid' in tasks:
    corr_matrix = (rest_corr_matrix + avoid_corr_matrix)/2
elif 'rest' in tasks and 'faces' in tasks:
    corr_matrix = (rest_corr_matrix + faces_corr_matrix)/2
elif 'avoid' in tasks and 'faces' in tasks:
    corr_matrix = (avoid_corr_matrix + faces_corr_matrix)/2
elif 'rest' in tasks:
    corr_matrix = rest_corr_matrix
elif 'avoid' in tasks:
    corr_matrix = avoid_corr_matrix
elif 'faces' in tasks:
    corr_matrix = faces_corr_matrix

# Create correlation matrix plot
plt.ioff()
corr_mat_plt = plt.matshow(corr_matrix)
plt.savefig(sesoutdir+'/'+sub+'_'+ses+'_atlas-seitz_corrmat.pdf')

# Write out correlation matrix
np.savetxt(sesoutdir+'/'+sub+'_'+ses+'_atlas-seitz_corrmat.csv',
    corr_matrix, delimiter=',')

##### Write out average amygdala connectivity
# Get amygdalae indices and average connectivity
amyg_indices = labels_df[labels_df['region'] == 4].index
amyg_corr = corr_matrix[amyg_indices]
amyg_ave_corr = (amyg_corr[0,] + amyg_corr[1,])/2 # average across right and left

# Name columns
subid = sub.split('-')[1]
sesid = ses.split('-')[1]

amyg_cols = ['region'+str(x) for x in range(1,301)]
amyg_df = pd.DataFrame(columns = amyg_cols)
amyg_df.loc[0] = amyg_ave_corr.T
amyg_df['subid'] = subid
amyg_df['sesid'] = sesid
cols = ['subid', 'sesid']
cols.extend(amyg_cols)
amyg_df = amyg_df[cols]

# Rename old
os.rename(sesoutdir+'/'+sub+'_'+ses+'_atlas-seitz_amygcorr.csv', sesoutdir+'/'+sub+'_'+ses+'_atlas-seitz_amygcorr_old.csv')

# Output new
amyg_df.to_csv(sesoutdir+'/'+sub+'_'+ses+'_atlas-seitz_amygcorr.csv', index=False)
