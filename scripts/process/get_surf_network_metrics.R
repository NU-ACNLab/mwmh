### This script is a first stab at creating a single subject template using
### templateICAr
### https://github.com/mandymejia/templateICAr
### Yeo networks: https://www.researchgate.net/figure/Network-parcellation-of-Yeos-17-networks-The-17-networks-include-the-following-regions_fig1_352966687#:~:text=The%2017%2Dnetworks%20include%20the%20following%20regions%3A%20N1%3A%20VisCent,N7%3A%20SalVentAttnA%20%2DSalience%2FVentral
###
### Ellyn Butler
### April 1, 2024

neuro_dir <- '~/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/'
template_obj <- readRDS(paste0(neuro_dir, 'template/HCP_template_for_tICA.rds'))

# Load libraries
library(templateICAr)
library(ciftiTools)
library(dplyr)
#library(RNifti)
ciftiTools.setOption('wb_path', '/Applications/workbench')

subid = 'MWMH317'
sesid = 1
task = 'rest'

neuro_dir <- '~/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/'
surf_dir <- paste0(neuro_dir, 'surf/')
rest_path <- paste0(surf_dir, 'sub-', subid, '/ses-', sesid, '/func/sub-', subid, 
    '_ses-', sesid, '_task-', task, '_space-fsLR_desc-postproc_bold.dscalar.nii')
rest_cifti <- read_cifti(rest_path)

bold_scans <- # vector of paths to all of the bold scans, just practicing with rest now


###### Mask out the medial wall
# load the medial wall image
hcp_dir <- '~/Documents/Northwestern/templates/HCP_S1200_GroupAvg_v1/'
mwall_path <- paste0(hcp_dir, 'Human.MedialWall_Conte69.32k_fs_LR.dlabel.nii')
mwall_cifti <- read_cifti(mwall_path)

# declare logical vectors for whether or not a given vertex is part of the medial wall
mwall_L <- c(mwall_cifti$data$cortex_left)
mwall_L <- recode(mwall_L, `0`=TRUE, `1`=FALSE)
mwall_R <- c(mwall_cifti$data$cortex_right)
mwall_R <- recode(mwall_R, `0`=TRUE, `1`=FALSE)

rest_cifti$data$cortex_left[!mwall_L,] <- NA
rest_cifti$data$cortex_right[!mwall_R,] <- NA

# set these vertices to NA
rest_cifti <- move_to_mwall(rest_cifti, values = NA)

# Write out resulting image

###### Load the template to serve as a prior (not using atm)
Yeo17 <- ciftiTools::load_parc('Yeo_17')
Yeo17_values <- as.matrix(Yeo17)
Yeo17_names <- Yeo17$meta$cifti$labels$parcels

xii <- read_cifti(ciftiTools.files()$cifti["dscalar_ones"], brainstructures="all")
subcort_names <- xii$meta$subcort$labels

#template <- #set of mean and between-subject variance maps for Yeo17... where can I get this?

###### Smooth the data
rest_cifti <- smooth_cifti(rest_cifti, surf_FWHM = 5)

###### Single subject template estimation 
networks_img <- templateICA(rest_cifti, template_obj, tvar_method = 'unbiased', 
            scale = 'local', TR = 0.555, scale_sm_FWHM = 0) 
            # for BOLD, can include multiple images
networks_img2 <- templateICA(rest_cifti, template_obj, tvar_method = 'unbiased', 
            scale = 'local', TR = 0.555, scale_sm_FWHM = 2) #not working

surfL <- read_surf(paste0(surf_dir, 'sub-', subid, '/anat/sub-', subid, 
    '.L.midthickness.32k_fs_LR.surf.gii'), expected_hemisphere = 'left')
surfR <- read_surf(paste0(surf_dir, 'sub-', subid, '/anat/sub-', subid, 
    '.R.midthickness.32k_fs_LR.surf.gii'), expected_hemisphere = 'right')

networks_img3 <- templateICA(rest_cifti, scale_sm_surfL = surfL, 
            scale_sm_surfR = surfR, template_obj, tvar_method = 'unbiased', 
            scale = 'local', TR = 0.555, scale_sm_FWHM = 0) 

networks_img4 <- templateICA(rest_cifti, scale_sm_surfL = surfL, 
            scale_sm_surfR = surfR, template_obj, tvar_method = 'unbiased', 
            scale = 'local', hpf = 0, scale_sm_FWHM = 2) 

###### Identify areas of engagement and deviation
network_membership <- activations(networks_img, verbose = TRUE)

#network_membership$active$data[[1]] 
# returns a matrix with 18 columns, one for each IC, and 32492 rows,
# one for each vertex. 
# 1 = positively engaged, 0 = not engaged, -1 = negatively engaged

# Salience/Ventral Attention A
sum(c(network_membership$active$data[[1]][, 8]) == 1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])
# 84.5% of the cortex is significantly engaged 

# Salience/Ventral Attention B
sum(c(network_membership$active$data[[1]][, 9]) == 1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])

###### Get the area that each network takes up (expansiveness)
surf_area(network_membership)

###### Estimate within network connectivity

###### Estimate amygdala betweenness centrality



