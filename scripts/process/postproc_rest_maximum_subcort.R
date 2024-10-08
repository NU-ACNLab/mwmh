### This script does maximum postprocessing on the resting
### state data to begin to get a sense of how much 
### post-processing we can get away with while still 
### getting a decent template
###
### Ellyn Butler
### August 6, 2024 - September 3, 2024

##### Load packages
library(argparse)
library(stats)
library(fMRIscrub)
library(fMRItools)
library(ciftiTools)
library(RNifti)
library(dplyr)
ciftiTools.setOption('wb_path', '/projects/b1108/software/workbench')

##### Set directories
indir <- '/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep_23.2.0/'
#indir <- '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep_23.2.0/'

outdir <- '/projects/b1108/studies/mwmh/data/processed/neuroimaging/surf/'
#outdir <- '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/surf/'

tmpdir <- '/projects/b1108/templates/fsl_first_subcortical/'
#tmpdir <- '~/Documents/Northwestern/templates/fsl_first_subcortical/'

##### Parse command line options
parser <- ArgumentParser()
parser$add_argument('-s', '--subid', type='character', help='Subject Identifier')
parser$add_argument('-e', '--sesid', type='character', help='Session Identifier')

args <- parser$parse_args()

subid = args$subid #'MWMH142'
sesid = args$sesid #1

##### Extract amygdala time series
BOLD <- readNifti( #dim = 75   94   79 1110
  paste0(indir, 'sub-', subid, '/ses-', sesid, '/func/sub-', subid, 
    '_ses-', sesid, '_task-rest_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz')
)

##### Post-process
## (L)
system(paste('wb_command -volume-resample', paste0(tmpdir, 'MNI_L_Amyg_bin_Cons.nii.gz'),
             paste0(indir, 'sub-', subid, '/ses-', sesid, '/func/sub-', subid, 
             '_ses-', sesid, '_task-rest_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz'),
             'ENCLOSING_VOXEL', paste0(outdir, 'sub-', subid, '/ses-', sesid, '/func/sub-', 
             subid, '_ses-', sesid, '_MNI_L_Amyg_bin_Cons_resampled.nii.gz')))

mask_L_rs <- readNifti( #dim = 75 94 79
    paste0(outdir, 'sub-', subid, '/ses-', sesid, '/func/sub-', 
             subid, '_ses-', sesid, '_MNI_L_Amyg_bin_Cons_resampled.nii.gz')
)

xii <- as.xifti(
  subcortVol = BOLD, #i \times j \times k \times T... dim(BOLD_L) = 1 1110... should be 75 94 79 1110, which is dim(BOLD)
  subcortLabs = factor( #i \times j \times k... length 1
    rep('Amygdala-L', sum(mask_L_rs)),
    levels=ciftiTools::substructure_table()$ciftiTools_Name
  ),
  subcortMask = mask_L_rs #i \times j \times k... dim = 75 94 79
)

# Get dimensions
x <- t(xii$data$subcort)
nT <- nrow(x)
nV <- ncol(x)

# Flagging
dv <- DVARS(x)
dv_flag <- dv$outlier_flag$Dual
dv_nS <- sum(dv_flag)

# One-hot encode outlier flags
dv_spikes <- matrix(0, nrow=nT, ncol=dv_nS)
dv_spikes[seq(0, dv_nS-1)*nT + which(dv_flag)] <- 1

# Select motion regressors
rp <- read.delim(paste0(indir, 'sub-', subid, '/ses-', sesid, '/func/sub-', subid, 
                '_ses-', sesid, '_task-rest_desc-confounds_timeseries.tsv'), sep = '\t')
rp <- rp[, c(paste0('trans_', c('x', 'y', 'z')), paste0('rot_', c('x', 'y', 'z')),
             paste0('trans_', c('x', 'y', 'z'), '_derivative1'), paste0('rot_', c('x', 'y', 'z'), '_derivative1'), 
             paste0('trans_', c('x', 'y', 'z'), '_power2'), paste0('rot_', c('x', 'y', 'z'), '_power2'),
             paste0('trans_', c('x', 'y', 'z'), '_derivative1_power2'), paste0('rot_', c('x', 'y', 'z'), '_derivative1_power2'),
             paste0('global_signal', c('_derivative1', '_power2', '_derivative1_power2')))]

# Set filtering parameters
dct <- dct_bases(nT, dct_convert(nT, TR=.555, f=.01)) # .01 Hz HPF

# Nuisance regression
nreg <- cbind(dv_spikes, rp, dct)
nreg[nreg == 'n/a'] <- 0
x_reg <- nuisance_regression(x, nreg)[!dv_flag,,drop=FALSE]
xii_out <- xii

xii_out$data$subcort <- t(x_reg)

# Write
write_cifti(xii_out, paste0(outdir, 'sub-', subid, '/ses-', sesid, '/func/sub-', subid, 
                '_ses-', sesid, '_task-rest_space-MNI152NLin6Asym_desc-maxpostproc_amygl.dtseries.nii'))

## (R)
system(paste('wb_command -volume-resample', paste0(tmpdir, 'MNI_R_Amyg_bin_Cons.nii.gz'),
             paste0(indir, 'sub-', subid, '/ses-', sesid, '/func/sub-', subid, 
             '_ses-', sesid, '_task-rest_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz'),
             'ENCLOSING_VOXEL', paste0(outdir, 'sub-', subid, '/ses-', sesid, '/func/sub-', 
             subid, '_ses-', sesid, '_MNI_R_Amyg_bin_Cons_resampled.nii.gz')))

mask_R_rs <- readNifti( #dim = 75 94 79
    paste0(outdir, 'sub-', subid, '/ses-', sesid, '/func/sub-', 
             subid, '_ses-', sesid, '_MNI_R_Amyg_bin_Cons_resampled.nii.gz')
)

xii <- as.xifti(
  subcortVol = BOLD, #i \times j \times k \times T... dim(BOLD_L) = 1 1110... should be 75 94 79 1110, which is dim(BOLD)
  subcortLabs = factor( #i \times j \times k... length 1
    rep('Amygdala-R', sum(mask_R_rs)),
    levels=ciftiTools::substructure_table()$ciftiTools_Name
  ),
  subcortMask = mask_R_rs #i \times j \times k... dim = 75 94 79
)

# Get dimensions
x <- t(rbind(xii$data$subcort))
nT <- nrow(x)
nV <- ncol(x)

# Flagging
dv <- DVARS(x)
dv_flag <- dv$outlier_flag$Dual
dv_nS <- sum(dv_flag)

# One-hot encode outlier flags
dv_spikes <- matrix(0, nrow=nT, ncol=dv_nS)
dv_spikes[seq(0, dv_nS-1)*nT + which(dv_flag)] <- 1

# Select motion regressors
rp <- read.delim(paste0(indir, 'sub-', subid, '/ses-', sesid, '/func/sub-', subid, 
                '_ses-', sesid, '_task-rest_desc-confounds_timeseries.tsv'), sep = '\t')
rp <- rp[, c(paste0('trans_', c('x', 'y', 'z')), paste0('rot_', c('x', 'y', 'z')),
             paste0('trans_', c('x', 'y', 'z'), '_derivative1'), paste0('rot_', c('x', 'y', 'z'), '_derivative1'), 
             paste0('trans_', c('x', 'y', 'z'), '_power2'), paste0('rot_', c('x', 'y', 'z'), '_power2'),
             paste0('trans_', c('x', 'y', 'z'), '_derivative1_power2'), paste0('rot_', c('x', 'y', 'z'), '_derivative1_power2'),
             paste0('global_signal', c('_derivative1', '_power2', '_derivative1_power2')))]

# Set filtering parameters
dct <- dct_bases(nT, dct_convert(nT, TR=.555, f=.01)) # .01 Hz HPF

# Nuisance regression
nreg <- cbind(dv_spikes, rp, dct)
nreg[nreg == 'n/a'] <- 0
x_reg <- nuisance_regression(x, nreg)[!dv_flag,,drop=FALSE]
xii_out <- xii

xii_out$data$subcort <- t(x_reg)

# Write
write_cifti(xii_out, paste0(outdir, 'sub-', subid, '/ses-', sesid, '/func/sub-', subid, 
                '_ses-', sesid, '_task-rest_space-MNI152NLin6Asym_desc-maxpostproc_amygr.dtseries.cii'))
