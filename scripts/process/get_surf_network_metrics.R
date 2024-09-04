### This script is a first stab at creating a single subject template using
### templateICAr
### https://github.com/mandymejia/templateICAr
### Yeo networks: https://www.researchgate.net/figure/Network-parcellation-of-Yeos-17-networks-The-17-networks-include-the-following-regions_fig1_352966687#:~:text=The%2017%2Dnetworks%20include%20the%20following%20regions%3A%20N1%3A%20VisCent,N7%3A%20exp_tAttnA%20%2DSalience%2FVentral
###
### Ellyn Butler
### July 31, 2024 - September 3, 2024

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
networks_img <- templateICA(cii, temp, tvar_method = 'unbiased', hpf = 0,
                scale = 'local', TR = 0.555, scale_sm_FWHM = 2, GSR = FALSE) 
                #Q (7/31/24): Still says "Pre-processing BOLD data"... What the heck is it doing? I turned off all of the options that are supposed to comprise preprocessing

saveRDS(networks_img, paste0(outdir, 'sub-', subid, '/ses-', sesid, '/networks_img.rds'))

###### Identify areas of engagement and deviation
network_membership <- activations(networks_img, verbose = TRUE, alpha = .01, method_p = 'bonferroni', type = 'abs >')
saveRDS(network_membership, paste0(outdir, 'sub-', subid, '/ses-', sesid, '/network_membership.rds'))
network_membership_pos <- activations(networks_img, verbose = TRUE, alpha = .01, method_p = 'bonferroni', type = '>')
saveRDS(network_membership_pos, paste0(outdir, 'sub-', subid, '/ses-', sesid, '/network_membership_pos.rds'))
network_membership_neg <- activations(networks_img, verbose = TRUE, alpha = .01, method_p = 'bonferroni', type = '<')
saveRDS(network_membership_neg, paste0(outdir, 'sub-', subid, '/ses-', sesid, '/network_membership_neg.rds'))

#network_membership$active$data[[1]] 
# returns a matrix with 17 columns, one for each IC, and 10242 rows,
# one for each vertex. 
# 1 = positively engaged, 0 = not engaged, -1 = negatively engaged

###### Get the area that each network takes up (expansiveness)
# Salience/Ventral Attention A # TO DO: [[1]] is just one of the hemispheres
exp_a_left <- sum(c(network_membership$active$data[[1]][, 7]) == 1 | c(network_membership$active$data[[1]][, 7]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])
exp_a_pos_left <- sum(c(network_membership$active$data[[1]][, 7]) == 1, na.rm = TRUE)/nrow(network_membership$active$data[[1]]) 
exp_a_neg_left <- sum(c(network_membership$active$data[[1]][, 7]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])

exp_a_right <- sum(c(network_membership$active$data[[2]][, 7]) == 1 | c(network_membership$active$data[[2]][, 7]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])
exp_a_pos_right <- sum(c(network_membership$active$data[[2]][, 7]) == 1, na.rm = TRUE)/nrow(network_membership$active$data[[2]]) 
exp_a_neg_right <- sum(c(network_membership$active$data[[2]][, 7]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[2]])

exp_a <- (sum(c(network_membership$active$data[[1]][, 7]) == 1 | c(network_membership$active$data[[1]][, 7]) == -1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 7]) == 1 | c(network_membership$active$data[[2]][, 7]) == -1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))
exp_a_pos <- (sum(c(network_membership$active$data[[1]][, 7]) == 1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 7]) == 1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))
exp_a_neg <- (sum(c(network_membership$active$data[[1]][, 7]) == -1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 7]) == -1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))

# Salience/Ventral Attention B
exp_b_left <- sum(c(network_membership$active$data[[1]][, 8]) == 1 | c(network_membership$active$data[[1]][, 8]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])
exp_b_pos_left <- sum(c(network_membership$active$data[[1]][, 8]) == 1, na.rm = TRUE)/nrow(network_membership$active$data[[1]]) 
exp_b_neg_left <- sum(c(network_membership$active$data[[1]][, 8]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])

exp_b_right <- sum(c(network_membership$active$data[[2]][, 8]) == 1 | c(network_membership$active$data[[2]][, 8]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[2]])
exp_b_pos_right <- sum(c(network_membership$active$data[[2]][, 8]) == 1, na.rm = TRUE)/nrow(network_membership$active$data[[2]]) 
exp_b_neg_right <- sum(c(network_membership$active$data[[2]][, 8]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[2]])

exp_b <- (sum(c(network_membership$active$data[[1]][, 8]) == 1 | c(network_membership$active$data[[1]][, 8]) == -1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 8]) == 1 | c(network_membership$active$data[[2]][, 8]) == -1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))
exp_b_pos <- (sum(c(network_membership$active$data[[1]][, 8]) == 1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 8]) == 1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]])) #probably the one I want to be analyzing because most similar to Lynch
exp_b_neg <- (sum(c(network_membership$active$data[[1]][, 8]) == -1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 8]) == -1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))

# # Salience/Ventral Attention A or B
exp_ab_left <- sum(c(network_membership$active$data[[1]][, 7]) == 1 | c(network_membership$active$data[[1]][, 8]) == 1 | c(network_membership$active$data[[1]][, 7]) == -1 | c(network_membership$active$data[[1]][, 8]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])
exp_ab_pos_left <- sum(c(network_membership$active$data[[1]][, 7]) == 1 | c(network_membership$active$data[[1]][, 8]) == 1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])
exp_ab_neg_left <- sum(c(network_membership$active$data[[1]][, 7]) == -1 | c(network_membership$active$data[[1]][, 8]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])

exp_ab_right <- sum(c(network_membership$active$data[[2]][, 7]) == 1 | c(network_membership$active$data[[2]][, 8]) == 1 | c(network_membership$active$data[[2]][, 7]) == -1 | c(network_membership$active$data[[2]][, 8]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[2]])
exp_ab_pos_right <- sum(c(network_membership$active$data[[2]][, 7]) == 1 | c(network_membership$active$data[[2]][, 8]) == 1, na.rm = TRUE)/nrow(network_membership$active$data[[2]])
exp_ab_neg_right <- sum(c(network_membership$active$data[[2]][, 7]) == -1 | c(network_membership$active$data[[2]][, 8]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[2]])

exp_ab <- (sum(c(network_membership$active$data[[1]][, 7]) == 1 | c(network_membership$active$data[[1]][, 8]) == 1 | c(network_membership$active$data[[1]][, 7]) == -1 | c(network_membership$active$data[[1]][, 8]) == -1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 7]) == 1 | c(network_membership$active$data[[2]][, 8]) == 1 | c(network_membership$active$data[[2]][, 7]) == -1 | c(network_membership$active$data[[2]][, 8]) == -1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))
exp_ab_pos <- (sum(c(network_membership$active$data[[1]][, 7]) == 1 | c(network_membership$active$data[[1]][, 8]) == 1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 7]) == 1 | c(network_membership$active$data[[2]][, 8]) == 1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))
exp_ab_neg <- (sum(c(network_membership$active$data[[1]][, 7]) == -1 | c(network_membership$active$data[[1]][, 8]) == -1, na.rm = TRUE) + sum(c(network_membership$active$data[[2]][, 7]) == -1 | c(network_membership$active$data[[2]][, 8]) == -1, na.rm = TRUE))/(nrow(network_membership$active$data[[1]]) + nrow(network_membership$active$data[[2]]))

###### Estimate within network connectivity
### Create FC matrix within SN
# Salience/Ventral Attention A
#vertices_a <- cii$data$cortex_left[, ] #9282 vertices versus 10242 active or not active...
cii <- move_from_mwall(cii, NA)

mask_a <- as.matrix(network_membership$active)[,7] != 0 #length(mask_a) = 20484
FC_mat_a <- cor(t(as.matrix(cii)[mask_a & complete.cases(as.matrix(cii)),])) 
FC_vec_a <- FC_mat_a[upper.tri(FC_mat_a)]
FC_a <- mean(FC_vec_a)

mask_a_pos <- as.matrix(network_membership$active)[,7] > 0
FC_mat_a_pos <- cor(t(as.matrix(cii)[mask_a_pos & complete.cases(as.matrix(cii)),])) #time series active locations by all the time points
FC_vec_a_pos <- FC_mat_a_pos[upper.tri(FC_mat_a_pos)]
FC_a_pos <- mean(FC_vec_a_pos)

mask_a_neg <- as.matrix(network_membership$active)[,7] < 0
FC_mat_a_neg <- cor(t(as.matrix(cii)[mask_a_neg & complete.cases(as.matrix(cii)),]))
FC_vec_a_neg <- FC_mat_a_neg[upper.tri(FC_mat_a_neg)]
FC_a_neg <- mean(FC_vec_a_neg)

# Salience/Ventral Attention B
mask_b <- as.matrix(network_membership$active)[,8] != 0
FC_mat_b <- cor(t(as.matrix(cii)[mask_b & complete.cases(as.matrix(cii)),])) 
FC_vec_b <- FC_mat_b[upper.tri(FC_mat_b)]
FC_b <- mean(FC_vec_b)

mask_b_pos <- as.matrix(network_membership$active)[,8] > 0
FC_mat_b_pos <- cor(t(as.matrix(cii)[mask_b_pos & complete.cases(as.matrix(cii)),])) 
FC_vec_b_pos <- FC_mat_b_pos[upper.tri(FC_mat_b_pos)]
FC_b_pos <- mean(FC_vec_b_pos)

mask_b_neg <- as.matrix(network_membership$active)[,8] < 0
FC_mat_b_neg <- cor(t(as.matrix(cii)[mask_b_neg & complete.cases(as.matrix(cii)),]))
FC_vec_b_neg <- FC_mat_a_neg[upper.tri(FC_mat_b_neg)]
FC_b_neg <- mean(FC_vec_b_neg)


###### Estimate amygdala betweenness centrality
# Load amygdala timeseries


# Calculate FC between amygdala and vertices in the SN (and put in matrix)

#FC_mat <- 

# Transform FC into "distances"
#FC_mat <- ((FC_mat*-1)+1)/2

# Use random walk to get estimates of 
#BC_amygdala_SN <- cbet(dist_mat_trans)

###### Output the data
df <- data.frame(subid = subid, sesid = sesid, 
                 exp_a_left = exp_a_left, exp_a_pos_left = exp_a_pos_left, 
                 exp_a_neg_left = exp_a_neg_left, 
                 exp_b_left = exp_b_left, exp_b_pos_left = exp_b_pos_left, 
                 exp_b_neg_left = exp_b_neg_left, 
                 exp_ab_left = exp_ab_left, exp_ab_pos_left = exp_ab_pos_left, 
                 exp_ab_neg_left = exp_ab_neg_left,
                 exp_a_right = exp_a_right, exp_a_pos_right = exp_a_pos_right, 
                 exp_a_neg_right = exp_a_neg_right, 
                 exp_b_right = exp_b_right, exp_b_pos_right = exp_b_pos_right, 
                 exp_b_neg_right = exp_b_neg_right, 
                 exp_ab_right = exp_ab_right, exp_ab_pos_right = exp_ab_pos_right, 
                 exp_ab_neg_right = exp_ab_neg_right,
                 exp_a = exp_a, exp_a_pos = exp_a_pos, exp_a_neg = exp_a_neg, 
                 exp_b = exp_b, exp_b_pos = exp_b_pos, exp_b_neg = exp_b_neg, 
                 exp_ab = exp_ab, exp_ab_pos = exp_ab_pos, exp_ab_neg = exp_ab_neg,
                 FC_a = FC_a, FC_a_pos = FC_a_pos, FC_a_neg = FC_a_neg,
                 FC_b = FC_b, FC_b_pos = FC_b_pos, FC_b_neg = FC_b_neg)

write.csv(df, paste0(outdir, 'sub-', subid, '/ses-', sesid, '/sub-', subid, '_ses-', 
                     sesid, '_surf_network_metrics.csv'), row.names = FALSE)

#Variables of interest: exp_b_pos, FC_b_pos, BC_b_pos