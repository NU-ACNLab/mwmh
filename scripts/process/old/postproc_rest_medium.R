### This script does medium postprocessing on the resting
### state data to begin to get a sense of how much 
### post-processing we can get away with while still 
### getting a decent template
###
### Ellyn Butler
### July 24, 2024 

##### Load packages
library(argparse)
library(stats)
library(fMRIscrub)
library(fMRItools)
library(ciftiTools)
ciftiTools.setOption('wb_path', '/projects/b1108/software/workbench')

##### Set directories
indir <- '/projects/b1108/studies/mwmh/data/processed/neuroimaging/'
#indir <- '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/'

motdir <- '/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep_23.2.0/'
#motdir <- '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep_23.2.0/'

##### Parse command line options
parser <- ArgumentParser()
parser$add_argument('-s', '--subid', type='character', help='Subject Identifier')
parser$add_argument('-e', '--sesid', type='character', help='Session Identifier')

args <- parser$parse_args()

subid = args$subid #'MWMH142'
sesid = args$sesid #1

##### Post-process
cii <- read_cifti(paste0(indir, 'surf/sub-', subid, '/ses-', sesid, '/func/sub-', subid, 
                '_ses-', sesid, '_task-rest_space-fsLR_desc-preproc_bold.dscalar.nii'))

# Mask out medial wall
GPARC <- readRDS(paste0(indir, 'template/GPARC.rds'))
mwall_L <- GPARC$meta$cortex$medial_wall$left
mwall_R <- GPARC$meta$cortex$medial_wall$right
cii$data$cortex_left[!mwall_L,] <- NA
cii$data$cortex_right[!mwall_R,] <- NA
cii <- move_to_mwall(cii, values = NA)

# Get dimensions
x <- t(rbind(cii$data$cortex_left, cii$data$cortex_right))
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
rp <- read.delim(paste0(motdir, 'sub-', subid, '/ses-', sesid, '/func/sub-', subid, 
                '_ses-', sesid, '_task-rest_desc-confounds_timeseries.tsv'), sep = '\t')
rp <- rp[, c(paste0('trans_', c('x', 'y', 'z')), paste0('rot_', c('x', 'y', 'z')),
             paste0('trans_', c('x', 'y', 'z'), '_derivative1'), paste0('rot_', c('x', 'y', 'z'), '_derivative1'), 
             paste0('trans_', c('x', 'y', 'z'), '_power2'), paste0('rot_', c('x', 'y', 'z'), '_power2'),
             paste0('trans_', c('x', 'y', 'z'), '_derivative1_power2'), paste0('rot_', c('x', 'y', 'z'), '_derivative1_power2'))]

# Set filtering parameters
dct <- dct_bases(nT, dct_convert(nT, TR=.555, f=.01)) # .01 Hz HPF

# Nuisance regression
nreg <- cbind(dv_spikes, rp, dct)
nreg[nreg == 'n/a'] <- 0
x_reg <- nuisance_regression(x, nreg)[!dv_flag,,drop=FALSE]
cii_out <- cii

nVertices_left <- nrow(cii$data$cortex_left)
cii_out$data$cortex_left <- t(x_reg[, 1:nVertices_left])
cii_out$data$cortex_right <- t(x_reg[, (nVertices_left+1):ncol(x_reg)])

# Smooth
cii_out$meta$cifti$names <- cii_out$meta$cifti$names[1:nrow(x_reg)]
cii_out <- smooth_cifti(cii_out, surf_FWHM = 5) 

# Downsample
cii_out <- resample_cifti(cii_out, resamp_res = 10000)

# Write
write_cifti(cii_out, paste0(indir, 'surf/sub-', subid, '/ses-', sesid, '/func/sub-', subid, 
                '_ses-', sesid, '_task-rest_space-fsLR_desc-medpostproc_bold.dscalar.nii'))
