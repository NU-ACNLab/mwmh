### This script does minimal postprocessing on the resting
### state data to begin to get a sense of how much 
### post-processing we can get away with while still 
### getting a decent template
###
### Ellyn Butler
### July 17, 2024 - 

##### Parse command line options

##### Load packages
library(fMRIscrub)
library(fMRItools)
library(ciftiTools)
ciftiTools.setOption('wb_path', '/projects/b1108/software/workbench')

##### Set directories
indir <- '/projects/b1108/studies/mwmh/data/processed/neuroimaging/'
#indir <- '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/'

motdir <- '/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep_23.2.0/'
#motdir <- '/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep_23.2.0/'

subid <- 'MWMH142'
sesid <- 1

##### Post-process
#x <- Dat1 # time by volumes
x <- read_cifti(paste0(indir, 'surf/sub-', subid, '/ses-', sesid, '/func/sub-', subid, 
                '_ses-', sesid, '_task-rest_space-fsLR_desc-preproc_bold.dscalar.nii'))
nT <- nrow(x)
nV <- ncol(x)

dv <- DVARS(x)
dv_flag <- dv$outlier_flag$Dual
dv_nS <- sum(dv_flag)
# One-hot encode outlier flags
dv_spikes <- matrix(0, nrow=nT, ncol=dv_nS)
dv_spikes[seq(0, dv_nS-1)*nT + which(dv_flag)] <- 1

# Select motion regressors
#rp <- cbind(rnorm(nT), rnorm(nT)) # fake other regressors, e.g. motion
rp <- read.delim(paste0(motdir, 'sub-', subid, '/ses-', sesid, '/func/sub-', subid, 
                '_ses-', sesid, '_task-rest_desc-confounds_timeseries.tsv'), sep = '\t')
rp <- rp[, c(paste0('trans_', c('x', 'y', 'z')), paste0('rot_', c('x', 'y', 'z')))]

# Set filtering parameters
dct <- dct_bases(nT, dct_convert(nT, TR=.72, f=.01)) # .01 Hz HPF
# ^any worries with filtering before dealing with flagged volumes?

# Nuisance regression
nreg <- cbind(dv_spikes, rp, dct)
x2 <- nuisance_regression(x, nreg)[!dv_flag,,drop=FALSE]

#> dim(rp)
#[1] 1110    6
#> dim(dv_spikes)
#[1] 64984    48
#> dim(dct)
#[1] 64984   935