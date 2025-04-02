### This script creates expansion and connectivity estimates
### for the other 15 Yeo17 networks. This script was created
### with the purpose of responding to reviewer comments asking
### to see results in the remaining 16 Yeo17 (Salience A metrics
### had already been estimated).
### https://github.com/mandymejia/templateICAr
### Yeo networks: https://www.researchgate.net/figure/Network-parcellation-of-Yeos-17-networks-The-17-networks-include-the-following-regions_fig1_352966687#:~:text=The%2017%2Dnetworks%20include%20the%20following%20regions%3A%20N1%3A%20VisCent,N7%3A%20exp_tAttnA%20%2DSalience%2FVentral
###
### Ellyn Butler
### March 30, 2025

# Load libraries
library(templateICAr)
library(ciftiTools)
library(dplyr)
library(argparse)
library(xtranat)
#ciftiTools.setOption('wb_path', '/Applications/workbench')
ciftiTools.setOption('wb_path', '/projects/b1108/software/workbench')

# Parse command line arguments
parser <- ArgumentParser()
parser$add_argument('-s', '--subid', type='character', help='Subject Identifier')
parser$add_argument('-e', '--sesid', type='character', help='Session Identifier')

args <- parser$parse_args()

subid = args$subid #'MWMH212'
sesid = args$sesid #2

print(subid)
print(sesid)

# Set paths
#neurodir <- '~/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/'
neurodir <- '/projects/b1108/studies/mwmh/data/processed/neuroimaging/'
temp <- readRDS(paste0(neurodir, 'template/temp_sub-ses2_ses-rand_task-rest_desc-maxpostproc.rds'))
#temp <- readRDS(paste0(neurodir, 'template/temp_sub-ses2_ses-rand_task-rest_desc-maxpostproc.rds'))

surfdir <- paste0(neurodir, 'surf/')
outdir <- paste0(neurodir, 'surfnet/')

###### Load the cifti
path <- paste0(surfdir, 'sub-', subid, '/ses-', sesid, '/func/sub-', subid, 
        '_ses-', sesid, '_task-rest_space-fsLR_desc-maxpostproc_bold.dscalar.nii')
cii <- read_cifti(path)

###### Identify areas of engagement and deviation
print('Load areas of engagement')
network_membership <- readRDS(paste0(outdir, 'sub-', subid, '/ses-', sesid, '/network_membership.rds'))

###### Get the area that each network takes up (expansiveness)
print('Expansion')

# Visual A (1)
exp_visuala_pos <- (sum(c(network_membership$active$data[[1]][, 1]) == 1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 1]) == 1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))

# Visual B (2)
exp_visualb_pos <- (sum(c(network_membership$active$data[[1]][, 2]) == 1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 2]) == 1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))

# Somatomotor A (3)
exp_somatomotora_pos <- (sum(c(network_membership$active$data[[1]][, 3]) == 1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 3]) == 1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))

# Somatomotor B (4)
exp_somatomotorb_pos <- (sum(c(network_membership$active$data[[1]][, 4]) == 1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 4]) == 1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))

# Dorsal Attention A (5)
exp_dorsalattentiona_pos <- (sum(c(network_membership$active$data[[1]][, 5]) == 1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 5]) == 1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))

# Dorsal Attention B (6)
exp_dorsalattentionb_pos <- (sum(c(network_membership$active$data[[1]][, 6]) == 1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 6]) == 1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))

# Limbic A (9)
exp_limbica_pos <- (sum(c(network_membership$active$data[[1]][, 9]) == 1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 9]) == 1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))

# Limbic B (10)
exp_limbicb_pos <- (sum(c(network_membership$active$data[[1]][, 10]) == 1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 10]) == 1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))

# Control A (11)
exp_controla_pos <- (sum(c(network_membership$active$data[[1]][, 11]) == 1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 11]) == 1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))

# Control B (12)
exp_controlb_pos <- (sum(c(network_membership$active$data[[1]][, 12]) == 1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 12]) == 1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))

# Control C (13)
exp_controlc_pos <- (sum(c(network_membership$active$data[[1]][, 13]) == 1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 13]) == 1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))

# Default A (14)
exp_defaulta_pos <- (sum(c(network_membership$active$data[[1]][, 14]) == 1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 14]) == 1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))

# Default B (15)
exp_defaultb_pos <- (sum(c(network_membership$active$data[[1]][, 15]) == 1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 15]) == 1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))

# Default C (16)
exp_defaultc_pos <- (sum(c(network_membership$active$data[[1]][, 16]) == 1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 16]) == 1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))

# Temporal Parietal (17)
exp_temporalparietal_pos <- (sum(c(network_membership$active$data[[1]][, 17]) == 1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 17]) == 1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))


###### Estimate within network connectivity
print('Connectivity')

cii <- move_from_mwall(cii, NA)

# Visual A (1)
mask_visuala_pos <- as.matrix(network_membership$active)[,1] > 0
FC_mat_visuala_pos <- cor(t(as.matrix(cii)[mask_visuala_pos & complete.cases(as.matrix(cii)),])) #time series active locations by all the time points
FC_vec_visuala_pos <- FC_mat_visuala_pos[upper.tri(FC_mat_visuala_pos)]
FC_visuala_pos <- mean(FC_vec_visuala_pos, na.rm = TRUE)

# Visual B (2)
mask_visualb_pos <- as.matrix(network_membership$active)[,2] > 0
FC_mat_visualb_pos <- cor(t(as.matrix(cii)[mask_visualb_pos & complete.cases(as.matrix(cii)),])) #time series active locations by all the time points
FC_vec_visualb_pos <- FC_mat_visualb_pos[upper.tri(FC_mat_visualb_pos)]
FC_visualb_pos <- mean(FC_vec_visualb_pos, na.rm = TRUE)

# Somatomotor A (3)
mask_somatomotora_pos <- as.matrix(network_membership$active)[,3] > 0
FC_mat_somatomotora_pos <- cor(t(as.matrix(cii)[mask_somatomotora_pos & complete.cases(as.matrix(cii)),])) #time series active locations by all the time points
FC_vec_somatomotora_pos <- FC_mat_somatomotora_pos[upper.tri(FC_mat_somatomotora_pos)]
FC_somatomotora_pos <- mean(FC_vec_somatomotora_pos, na.rm = TRUE)

# Somatomotor B (4)
mask_somatomotorb_pos <- as.matrix(network_membership$active)[,4] > 0
FC_mat_somatomotorb_pos <- cor(t(as.matrix(cii)[mask_somatomotorb_pos & complete.cases(as.matrix(cii)),])) #time series active locations by all the time points
FC_vec_somatomotorb_pos <- FC_mat_somatomotorb_pos[upper.tri(FC_mat_somatomotorb_pos)]
FC_somatomotorb_pos <- mean(FC_vec_somatomotorb_pos, na.rm = TRUE)

# Dorsal Attention A (5)
mask_dorsalattentiona_pos <- as.matrix(network_membership$active)[,5] > 0
FC_mat_dorsalattentiona_pos <- cor(t(as.matrix(cii)[mask_dorsalattentiona_pos & complete.cases(as.matrix(cii)),])) #time series active locations by all the time points
FC_vec_dorsalattentiona_pos <- FC_mat_dorsalattentiona_pos[upper.tri(FC_mat_dorsalattentiona_pos)]
FC_dorsalattentiona_pos <- mean(FC_vec_dorsalattentiona_pos, na.rm = TRUE)

# Dorsal Attention B (6)
mask_dorsalattentionb_pos <- as.matrix(network_membership$active)[,6] > 0
FC_mat_dorsalattentionb_pos <- cor(t(as.matrix(cii)[mask_dorsalattentionb_pos & complete.cases(as.matrix(cii)),])) #time series active locations by all the time points
FC_vec_dorsalattentionb_pos <- FC_mat_dorsalattentionb_pos[upper.tri(FC_mat_dorsalattentionb_pos)]
FC_dorsalattentionb_pos <- mean(FC_vec_dorsalattentionb_pos, na.rm = TRUE)

# Limbic A (9)
mask_limbica_pos <- as.matrix(network_membership$active)[,9] > 0
FC_mat_limbica_pos <- cor(t(as.matrix(cii)[mask_limbica_pos & complete.cases(as.matrix(cii)),])) #time series active locations by all the time points
FC_vec_limbica_pos <- FC_mat_limbica_pos[upper.tri(FC_mat_limbica_pos)]
FC_limbica_pos <- mean(FC_vec_limbica_pos, na.rm = TRUE)

# Limbic B (10)
mask_limbicb_pos <- as.matrix(network_membership$active)[,10] > 0
FC_mat_limbicb_pos <- cor(t(as.matrix(cii)[mask_limbicb_pos & complete.cases(as.matrix(cii)),])) #time series active locations by all the time points
FC_vec_limbicb_pos <- FC_mat_limbicb_pos[upper.tri(FC_mat_limbicb_pos)]
FC_limbicb_pos <- mean(FC_vec_limbicb_pos, na.rm = TRUE)

# Control A (11)
mask_controla_pos <- as.matrix(network_membership$active)[,11] > 0
FC_mat_controla_pos <- cor(t(as.matrix(cii)[mask_controla_pos & complete.cases(as.matrix(cii)),])) #time series active locations by all the time points
FC_vec_controla_pos <- FC_mat_controla_pos[upper.tri(FC_mat_controla_pos)]
FC_controla_pos <- mean(FC_vec_controla_pos, na.rm = TRUE)

# Control B (12)
mask_controlb_pos <- as.matrix(network_membership$active)[,12] > 0
FC_mat_controlb_pos <- cor(t(as.matrix(cii)[mask_controlb_pos & complete.cases(as.matrix(cii)),])) #time series active locations by all the time points
FC_vec_controlb_pos <- FC_mat_controlb_pos[upper.tri(FC_mat_controlb_pos)]
FC_controlb_pos <- mean(FC_vec_controlb_pos, na.rm = TRUE)

# Control C (13)
mask_controlc_pos <- as.matrix(network_membership$active)[,13] > 0
FC_mat_controlc_pos <- cor(t(as.matrix(cii)[mask_controlc_pos & complete.cases(as.matrix(cii)),])) #time series active locations by all the time points
FC_vec_controlc_pos <- FC_mat_controlc_pos[upper.tri(FC_mat_controlc_pos)]
FC_controlc_pos <- mean(FC_vec_controlc_pos, na.rm = TRUE)

# Default A (14)
mask_defaulta_pos <- as.matrix(network_membership$active)[,14] > 0
FC_mat_defaulta_pos <- cor(t(as.matrix(cii)[mask_defaulta_pos & complete.cases(as.matrix(cii)),])) #time series active locations by all the time points
FC_vec_defaulta_pos <- FC_mat_defaulta_pos[upper.tri(FC_mat_defaulta_pos)]
FC_defaulta_pos <- mean(FC_vec_defaulta_pos, na.rm = TRUE)

# Default B (15)
mask_defaultb_pos <- as.matrix(network_membership$active)[,15] > 0
FC_mat_defaultb_pos <- cor(t(as.matrix(cii)[mask_defaultb_pos & complete.cases(as.matrix(cii)),])) #time series active locations by all the time points
FC_vec_defaultb_pos <- FC_mat_defaultb_pos[upper.tri(FC_mat_defaultb_pos)]
FC_defaultb_pos <- mean(FC_vec_defaultb_pos, na.rm = TRUE)

# Default C (16)
mask_defaultc_pos <- as.matrix(network_membership$active)[,16] > 0
FC_mat_defaultc_pos <- cor(t(as.matrix(cii)[mask_defaultc_pos & complete.cases(as.matrix(cii)),])) #time series active locations by all the time points
FC_vec_defaultc_pos <- FC_mat_defaultc_pos[upper.tri(FC_mat_defaultc_pos)]
FC_defaultc_pos <- mean(FC_vec_defaultc_pos, na.rm = TRUE)

# Temporal Parietal (17)
mask_temporalparietal_pos <- as.matrix(network_membership$active)[,17] > 0
FC_mat_temporalparietal_pos <- cor(t(as.matrix(cii)[mask_temporalparietal_pos & complete.cases(as.matrix(cii)),])) #time series active locations by all the time points
FC_vec_temporalparietal_pos <- FC_mat_temporalparietal_pos[upper.tri(FC_mat_temporalparietal_pos)]
FC_temporalparietal_pos <- mean(FC_vec_temporalparietal_pos, na.rm = TRUE)


###### Output the data
print('Output')

df <- data.frame(subid = subid, sesid = sesid, 
                 exp_visuala_pos = exp_visuala_pos, exp_visualb_pos = exp_visualb_pos,
                 exp_somatomotora_pos = exp_somatomotora_pos, 
                 exp_somatomotorb_pos = exp_somatomotorb_pos,
                 exp_dorsalattentiona_pos = exp_dorsalattentiona_pos, 
                 exp_dorsalattentionb_pos = exp_dorsalattentionb_pos,
                 exp_limbica_pos = exp_limbica_pos, exp_limbicb_pos = exp_limbicb_pos,
                 exp_controla_pos = exp_controla_pos, exp_controlb_pos = exp_controlb_pos,
                 exp_controlc_pos = exp_controlc_pos, exp_defaulta_pos = exp_defaulta_pos,
                 exp_defaultb_pos = exp_defaultb_pos, exp_defaultc_pos = exp_defaultc_pos,
                 exp_temporalparietal_pos = exp_temporalparietal_pos,
                 FC_visuala_pos = FC_visuala_pos, FC_visualb_pos = FC_visualb_pos,
                 FC_somatomotora_pos = FC_somatomotora_pos,
                 FC_somatomotorb_pos = FC_somatomotorb_pos,
                 FC_dorsalattentiona_pos = FC_dorsalattentiona_pos, 
                 FC_dorsalattentionb_pos = FC_dorsalattentionb_pos,
                 FC_limbica_pos = FC_limbica_pos, FC_limbicb_pos = FC_limbicb_pos,
                 FC_controla_pos = FC_controla_pos, FC_controlb_pos = FC_controlb_pos,
                 FC_controlc_pos = FC_controlc_pos, FC_defaulta_pos = FC_defaulta_pos,
                 FC_defaultb_pos = FC_defaultb_pos, FC_defaultc_pos = FC_defaultc_pos,
                 FC_temporalparietal_pos = FC_temporalparietal_pos
                 )

write.csv(df, paste0(outdir, 'sub-', subid, '/ses-', sesid, '/sub-', subid, '_ses-', 
                     sesid, '_surf_network_metrics_15.csv'), row.names = FALSE)
