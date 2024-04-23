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

# set these vertices to NA... not working
rest_cifti <- move_to_mwall(rest_cifti, values = NA)

###### Downsample surfaces (if necessary)... working
#rest_cifti <- resample_cifti(rest_cifti, resamp_res = 10000)

###### Add in subcortical data - TO DO
# Load postproc image in MNI space
postproc_dir <- '~/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/postproc/'
rest_mni_path <- paste0(postproc_dir, 'sub-', subid, '/ses-', sesid, '/sub-', subid, 
    '_ses-', sesid, '_task-', task, '_space-MNI152NLin6Asym_desc-postproc_bold.nii.gz')
subcort_path <- paste0(surf_dir, 'sub-', subid, '/ses-', sesid, '/func/sub-', subid, 
    '_ses-', sesid, '_task-', task, '_space-fsLR_desc-subcort_bold.dscalar.nii')
subcort_atlas_path <- '~/Documents/Northwestern/templates/91282_Greyordinates/91282_Greyordinates.dscalar.nii'
#rest_mni <- readNifti(rest_mni_path) #from another package, not clear if this will work
## Example command using wb_command (part of Connectome Workbench)


system(paste('wb_command -cifti-create-dense-from-template', subcort_atlas_path, subcort_path,
                '-volume-all', rest_mni_path))
# 
parc_add_subcortex()

# Write out resulting image

###### Load the template to serve as a prior
Yeo17 <- ciftiTools::load_parc('Yeo_17')
Yeo17_values <- as.matrix(Yeo17)
Yeo17_names <- Yeo17$meta$cifti$labels$parcels

xii <- read_cifti(ciftiTools.files()$cifti["dscalar_ones"], brainstructures="all")
subcort_names <- xii$meta$subcort$labels

#template <- #set of mean and between-subject variance maps for Yeo17... where can I get this?

###### Single subject template estimation - not working
networks_img <- templateICA(rest_cifti, template_obj, tvar_method = 'unbiased', 
            scale = 'global', TR = 0.555, scale_sm_FWHM = 0) 
            # for BOLD, can include multiple images

###### Identify areas of engagement and deviation
network_membership <- activations(networks_img, verbose = TRUE)

###### Get the area that each network takes up (expansiveness)
surf_area(network_membership)

###### Estimate within network connectivity

###### Estimate amygdala betweenness centrality



