### This script is a first stab at creating a single subject template using
### templateICAr
### https://github.com/mandymejia/templateICAr
### Yeo networks: https://www.researchgate.net/figure/Network-parcellation-of-Yeos-17-networks-The-17-networks-include-the-following-regions_fig1_352966687#:~:text=The%2017%2Dnetworks%20include%20the%20following%20regions%3A%20N1%3A%20VisCent,N7%3A%20SalVentAttnA%20%2DSalience%2FVentral
###
### Ellyn Butler
### April 1, 2024 - May 23, 2024

# Load libraries
library(templateICAr)
library(ciftiTools)
library(dplyr)
library(argparse)
#ciftiTools.setOption('wb_path', '/Applications/workbench')
ciftiTools.setOption('wb_path', '/projects/b1108/software/workbench')

# Parse command line arguments
parser <- ArgumentParser()
parser$add_argument('s', '--subid', type='character', help='Subject Identifier')
parser$add_argument('e', '--sesid', type='character', help='Session Identifier')
parser$add_argument('t', '--tasks', nargs='+', help='fMRI tasks (rest, faces, avoid)')

args <- parser$parse_args()

subid = parser$subid #'MWMH317'
sesid = parser$sesid #1
tasks = parser$tasks #c('rest', 'faces', 'avoid')

# Set paths
#neurodir <- '~/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/'
neurodir <- '/projects/b1108/studies/mwmh/data/processed/neuroimaging/'
temp <- readRDS(paste0(neurodir, 'template_Yeo17/temp.rds'))

#hcpdir <- '~/Documents/Northwestern/templates/HCP_S1200_GroupAvg_v1/'
hcpdir <- '/projects/b1108/templates/HCP_S1200_GroupAvg_v1/'
surfdir <- paste0(neurodir, 'surf/')
outdir <- paste0(neurodir, 'surfnet/')

i = 1
for (task in tasks) {
    path <- paste0(surfdir, 'sub-', subid, '/ses-', sesid, '/func/sub-', subid, 
        '_ses-', sesid, '_task-', task, '_space-fsLR_desc-postproc_bold.dscalar.nii')
    cifti <- read_cifti(path)
    if (i == 1) {
        cii <- cifti
    } else {
        cii <- merge_xifti(cii, cifti)
    }
    i = i + 1
}

###### Mask out the medial wall
# declare logical vectors for whether or not a given vertex is part of the medial wall
temp_mwall <- do.call(c, temp$dat_struct$meta$cortex$medial_wall_mask)
cii_mat <- as.matrix(cii)
cii_mat[!temp_mwall,] <- NA
cii <- move_to_mwall(newdata_xifti(cii, cii_mat), NA)

###### Smooth the data
cii <- smooth_cifti(cii, surf_FWHM = 5)

# Write out resulting image
dir.create(paste0(outdir, 'sub-', subid), showWarnings = TRUE)
dir.create(paste0(outdir, 'sub-', subid, '/ses-', sesid), showWarnings = TRUE)
write_cifti(cii, paste0(outdir, 'sub-', subid, '/ses-', sesid, '/sub-', subid, '_ses-', 
        sesid, '_task-all_space-fsLR_desc-smoothed_bold.dscalar.nii'))

###### Single subject template estimation 
networks_img <- templateICA(cii, temp, tvar_method = 'unbiased', hpf = 0,
            scale = 'local', TR = 0.555, scale_sm_FWHM = 2) 

saveRDS(networks_img, paste0(outdir, 'sub-', subid, '/ses-', sesid, '/networks_img.rds'))

###### Identify areas of engagement and deviation
network_membership <- activations(networks_img, verbose = TRUE)
saveRDS(network_membership, paste0(outdir, 'sub-', subid, '/ses-', sesid, '/network_membership.rds'))

#network_membership$active$data[[1]] 
# returns a matrix with 18 columns, one for each IC, and 32492 rows,
# one for each vertex. 
# 1 = positively engaged, 0 = not engaged, -1 = negatively engaged

# Salience/Ventral Attention A
salvena <- sum(c(network_membership$active$data[[1]][, 7]) == 1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])
# 84.5% of the cortex is significantly engaged 

# Salience/Ventral Attention B
salvenb <- sum(c(network_membership$active$data[[1]][, 8]) == 1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])

###### Get the area that each network takes up (expansiveness)
sa <- surf_area(network_membership)

###### Estimate within network connectivity

###### Estimate amygdala betweenness centrality



