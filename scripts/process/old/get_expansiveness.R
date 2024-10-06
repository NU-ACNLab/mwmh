### This script is a first stab at creating a single subject template using
### templateICAr
### https://github.com/mandymejia/templateICAr
### Yeo networks: https://www.researchgate.net/figure/Network-parcellation-of-Yeos-17-networks-The-17-networks-include-the-following-regions_fig1_352966687#:~:text=The%2017%2Dnetworks%20include%20the%20following%20regions%3A%20N1%3A%20VisCent,N7%3A%20SalVentAttnA%20%2DSalience%2FVentral
###
### Ellyn Butler
### July 31, 2024 - August 6, 2024

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
        network_membership <- activations(networks_img, verbose = TRUE, alpha = .00000000001)
        saveRDS(network_membership, paste0(outdir, 'sub-', subid, '/ses-', sesid, '/network_membership.rds'))
} else {
        networks_img <- readRDS(paste0(outdir, 'sub-', subid, '/ses-', sesid, '/networks_img.rds'))
        network_membership <- readRDS(paste0(outdir, 'sub-', subid, '/ses-', sesid, '/network_membership.rds'))
}
#network_membership$active$data[[1]] 
# returns a matrix with 17 columns, one for each IC, and 10242 rows,
# one for each vertex. 
# 1 = positively engaged, 0 = not engaged, -1 = negatively engaged

###### Get the area that each network takes up (expansiveness)
# Salience/Ventral Attention A
salvena <- sum(c(network_membership$active$data[[1]][, 7]) == 1 | c(network_membership$active$data[[1]][, 7]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])
salvena_pos <- sum(c(network_membership$active$data[[1]][, 7]) == 1, na.rm = TRUE)/nrow(network_membership$active$data[[1]]) 
salvena_neg <- sum(c(network_membership$active$data[[1]][, 7]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])

# Salience/Ventral Attention B
salvenb <- sum(c(network_membership$active$data[[1]][, 8]) == 1 | c(network_membership$active$data[[1]][, 8]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])
salvenb_pos <- sum(c(network_membership$active$data[[1]][, 8]) == 1, na.rm = TRUE)/nrow(network_membership$active$data[[1]]) #probably the one I want to be analyzing because most similar to Lynch
salvenb_neg <- sum(c(network_membership$active$data[[1]][, 8]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])

# # Salience/Ventral Attention A or B
salvenab <- sum(c(network_membership$active$data[[1]][, 7]) == 1 | c(network_membership$active$data[[1]][, 8]) == 1 | c(network_membership$active$data[[1]][, 7]) == -1 | c(network_membership$active$data[[1]][, 8]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])
salvenab_pos <- sum(c(network_membership$active$data[[1]][, 7]) == 1 | c(network_membership$active$data[[1]][, 8]) == 1, na.rm = TRUE)/nrow(network_membership$active$data[[1]]) 
salvenab_neg <- sum(c(network_membership$active$data[[1]][, 7]) == -1 | c(network_membership$active$data[[1]][, 8]) == -1, na.rm = TRUE)/nrow(network_membership$active$data[[1]])

###### Output the data
df <- data.frame(subid=subid, sesid=sesid, 
                 salvena=salvena, salvena_pos=salvena_pos, salvena_neg=salvena_neg, 
                 salvenb=salvenb, salvenb_pos=salvenb_pos, salvenb_neg=salvenb_neg, 
                 salvenab=salvenab, salvenab_pos=salvenab_pos, salvenab_neg=salvenab_neg)
write.csv(df, paste0(outdir, 'sub-', subid, '/ses-', sesid, '/sub-', subid, '_ses-', sesid,
                     '_expansiveness.csv'), row.names = FALSE)