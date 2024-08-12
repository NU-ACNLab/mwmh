### This script is a first stab at creating a single subject template using
### templateICAr
### https://github.com/mandymejia/templateICAr
### Yeo networks: https://www.researchgate.net/figure/Network-parcellation-of-Yeos-17-networks-The-17-networks-include-the-following-regions_fig1_352966687#:~:text=The%2017%2Dnetworks%20include%20the%20following%20regions%3A%20N1%3A%20VisCent,N7%3A%20SalVentAttnA%20%2DSalience%2FVentral
###
### Ellyn Butler
### July 31, 2024

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
temp <- readRDS(paste0(neurodir, 'template/temp_sub-1ses_task-rest_desc-maxpostproc.rds'))
#temp <- readRDS(paste0(neurodir, 'template/temp_sub-all_ses-2_task-rest_desc-maxpostproc.rds'))

#hcpdir <- '~/Documents/Northwestern/templates/HCP_S1200_GroupAvg_v1/'
hcpdir <- '/projects/b1108/templates/HCP_S1200_GroupAvg_v1/'
surfdir <- paste0(neurodir, 'surf/')
outdir <- paste0(neurodir, 'surfnet/')

###### Load the cifti
path <- paste0(surfdir, 'sub-', subid, '/ses-', sesid, '/func/sub-', subid, 
        '_ses-', sesid, '_task-rest_space-fsLR_desc-maxpostproc_bold.dscalar.nii')
cii <- read_cifti(path)

###### Single subject template estimation 
if (!file.exists(paste0(outdir, 'sub-', subid, '/ses-', sesid, '/network_membership.rds'))) {
        networks_img <- templateICA(cii, temp, tvar_method = 'unbiased', hpf = 0,
                scale = 'local', TR = 0.555, scale_sm_FWHM = 2, GSR = FALSE) 
                #Q (7/31/24): Still says "Pre-processing BOLD data"... What the heck is it doing? I turned off all of the options that are supposed to comprise preprocessing

        saveRDS(networks_img, paste0(outdir, 'sub-', subid, '/ses-', sesid, '/networks_img.rds'))

        ###### Identify areas of engagement and deviation
        network_membership <- activations(networks_img, verbose = TRUE, alpha = .01, method_p = 'Bonferroni', type = 'abs >')
        saveRDS(network_membership, paste0(outdir, 'sub-', subid, '/ses-', sesid, '/network_membership.rds'))
        network_membership_pos <- activations(networks_img, verbose = TRUE, alpha = .01, method_p = 'Bonferroni', type = '>')
        saveRDS(network_membership_pos, paste0(outdir, 'sub-', subid, '/ses-', sesid, '/network_membership_pos.rds'))
        network_membership_neg <- activations(networks_img, verbose = TRUE, alpha = .01, method_p = 'Bonferroni', type = '<')
        saveRDS(network_membership_neg, paste0(outdir, 'sub-', subid, '/ses-', sesid, '/network_membership_neg.rds'))
} else {
        networks_img <- readRDS(paste0(outdir, 'sub-', subid, '/ses-', sesid, '/networks_img.rds'))
        network_membership <- readRDS(paste0(outdir, 'sub-', subid, '/ses-', sesid, '/network_membership.rds'))
}
#network_membership$active$data[[1]] 
# returns a matrix with 17 columns, one for each IC, and 10242 rows,
# one for each vertex. 
# 1 = positively engaged, 0 = not engaged, -1 = negatively engaged

###### Get the area that each network takes up (expansiveness)
# Salience/Ventral Attention A # TO DO: [[1]] is just one of the hemispheres
salvena_left <- sum(c(network_membership$active$data[[1]][, 7]) == 1 | c(network_membership$active$data[[1]][, 7]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])
salvena_pos_left <- sum(c(network_membership$active$data[[1]][, 7]) == 1, na.rm = TRUE)/nrow(network_membership$active$data[[1]]) 
salvena_neg_left <- sum(c(network_membership$active$data[[1]][, 7]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])

salvena_right <- sum(c(network_membership$active$data[[2]][, 7]) == 1 | c(network_membership$active$data[[2]][, 7]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])
salvena_pos_right <- sum(c(network_membership$active$data[[2]][, 7]) == 1, na.rm = TRUE)/nrow(network_membership$active$data[[2]]) 
salvena_neg_right <- sum(c(network_membership$active$data[[2]][, 7]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[2]])

salvena <- (sum(c(network_membership$active$data[[1]][, 7]) == 1 | c(network_membership$active$data[[1]][, 7]) == -1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 7]) == 1 | c(network_membership$active$data[[2]][, 7]) == -1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))
salvena_pos <- (sum(c(network_membership$active$data[[1]][, 7]) == 1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 7]) == 1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))
salvena_neg <- (sum(c(network_membership$active$data[[1]][, 7]) == -1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 7]) == -1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))

# Salience/Ventral Attention B
salvenb_left <- sum(c(network_membership$active$data[[1]][, 8]) == 1 | c(network_membership$active$data[[1]][, 8]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])
salvenb_pos_left <- sum(c(network_membership$active$data[[1]][, 8]) == 1, na.rm = TRUE)/nrow(network_membership$active$data[[1]]) #probably the one I want to be analyzing because most similar to Lynch
salvenb_neg_left <- sum(c(network_membership$active$data[[1]][, 8]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])

salvenb_right <- sum(c(network_membership$active$data[[2]][, 8]) == 1 | c(network_membership$active$data[[2]][, 8]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[2]])
salvenb_pos_right <- sum(c(network_membership$active$data[[2]][, 8]) == 1, na.rm = TRUE)/nrow(network_membership$active$data[[2]]) #probably the one I want to be analyzing because most similar to Lynch
salvenb_neg_right <- sum(c(network_membership$active$data[[2]][, 8]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[2]])

salvenb <- (sum(c(network_membership$active$data[[1]][, 8]) == 1 | c(network_membership$active$data[[1]][, 8]) == -1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 8]) == 1 | c(network_membership$active$data[[2]][, 8]) == -1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))
salvenb_pos <- (sum(c(network_membership$active$data[[1]][, 8]) == 1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 8]) == 1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))
salvenb_neg <- (sum(c(network_membership$active$data[[1]][, 8]) == -1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 8]) == -1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))

# # Salience/Ventral Attention A or B
salvenab_left <- sum(c(network_membership$active$data[[1]][, 7]) == 1 | c(network_membership$active$data[[1]][, 8]) == 1 | c(network_membership$active$data[[1]][, 7]) == -1 | c(network_membership$active$data[[1]][, 8]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])
salvenab_pos_left <- sum(c(network_membership$active$data[[1]][, 7]) == 1 | c(network_membership$active$data[[1]][, 8]) == 1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])
salvenab_neg_left <- sum(c(network_membership$active$data[[1]][, 7]) == -1 | c(network_membership$active$data[[1]][, 8]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])

salvenab_right <- sum(c(network_membership$active$data[[2]][, 7]) == 1 | c(network_membership$active$data[[2]][, 8]) == 1 | c(network_membership$active$data[[2]][, 7]) == -1 | c(network_membership$active$data[[2]][, 8]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[2]])
salvenab_pos_right <- sum(c(network_membership$active$data[[2]][, 7]) == 1 | c(network_membership$active$data[[2]][, 8]) == 1, na.rm = TRUE)/nrow(network_membership$active$data[[2]])
salvenab_neg_right <- sum(c(network_membership$active$data[[2]][, 7]) == -1 | c(network_membership$active$data[[2]][, 8]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[2]])

salvenab <- (sum(c(network_membership$active$data[[1]][, 7]) == 1 | c(network_membership$active$data[[1]][, 8]) == 1 | c(network_membership$active$data[[1]][, 7]) == -1 | c(network_membership$active$data[[1]][, 8]) == -1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 7]) == 1 | c(network_membership$active$data[[2]][, 8]) == 1 | c(network_membership$active$data[[2]][, 7]) == -1 | c(network_membership$active$data[[2]][, 8]) == -1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))
salvenab_pos <- (sum(c(network_membership$active$data[[1]][, 7]) == 1 | c(network_membership$active$data[[1]][, 8]) == 1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 7]) == 1 | c(network_membership$active$data[[2]][, 8]) == 1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))
salvenab_neg <- (sum(c(network_membership$active$data[[1]][, 7]) == -1 | c(network_membership$active$data[[1]][, 8]) == -1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 7]) == -1 | c(network_membership$active$data[[2]][, 8]) == -1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))

###### Estimate within network connectivity
### Create FC matrix within SN
# Salience/Ventral Attention A
#vertices_a <- cii$data$cortex_left[, ] #9282 vertices versus 10242 active or not active...
cii <- move_from_mwall(cii, NA)

mask_a <- as.matrix(network_membership$active)[,7] != 0
FC_mat_a <- as.matrix(cii)[mask_a,,drop=FALSE]
mask_a_pos <- as.matrix(network_membership$active)[,7] > 0
FC_mat_a_pos <- as.matrix(cii)[mask_a_pos,,drop=FALSE] #time series active locations by all the time points
mask_a_neg <- as.matrix(network_membership$active)[,7] < 0
FC_mat_a_neg <-  

# Salience/Ventral Attention B
FC_mat_b <- 
FC_mat_b_pos <- 
FC_mat_b_neg <- 

# # Salience/Ventral Attention A or B
FC_mat_ab <- 
FC_mat_ab_pos <- 
FC_mat_ab_neg <- 

# Turn the upper triangle into a vector
FC_vec <- FC_mat[upper.tri(FC_mat)]

# Average
FC_within_SN <- mean(FC_vec)

###### Estimate amygdala betweenness centrality
# Load amygdala timeseries


# Calculate FC between amygdala and vertices in the SN (and put in matrix)

FC_mat <- 

# Transform FC into "distances"
FC_mat <- ((FC_mat*-1)+1)/2

# Use random walk to get estimates of 
BC_amygdala_SN <- cbet(dist_mat_trans)

###### Output the data
df <- data.frame(subid = subid, sesid = sesid, 
                 salvena_left = salvena_left, salvena_pos_left = salvena_pos_left, 
                 salvena_neg_left = salvena_neg_left, 
                 salvenb_left = salvenb_left, salvenb_pos_left = salvenb_pos_left, 
                 salvenb_neg_left = salvenb_neg_left, 
                 salvenab_left = salvenab_left, salvenab_pos_left = salvenab_pos_left, 
                 salvenab_neg_left = salvenab_neg_left,
                 salvena_right = salvena_right, salvena_pos_right = salvena_pos_right, 
                 salvena_neg_right = salvena_neg_right, 
                 salvenb_right = salvenb_right, salvenb_pos_right = salvenb_pos_right, 
                 salvenb_neg_right = salvenb_neg_right, 
                 salvenab_right = salvenab_right, salvenab_pos_right = salvenab_pos_right, 
                 salvenab_neg_right = salvenab_neg_right,
                 salvena = salvena, salvena_pos = salvena_pos, salvena_neg = salvena_neg, 
                 salvenb = salvenb, salvenb_pos = salvenb_pos, salvenb_neg = salvenb_neg, 
                 salvenab = salvenab, salvenab_pos = salvenab_pos, salvenab_neg = salvenab_neg,
                 FC_within_SN=FC_within_SN, 
                 BC_amygdala_SN=BC_amygdala_SN)
write.csv(df, paste0(outdir, 'sub-', subid, '/ses-', sesid, '/'))