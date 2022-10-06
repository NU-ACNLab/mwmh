### This script compares the scans in BIDS to the scans with outputs from fMRIPrep
### to ensure that everything we have was processed.
###
### Ellyn Butler
### October 6, 2022

bids_df <- read.csv('/projects/b1108/studies/mwmh/data/raw/neuroimaging/meta/bids_10-06-2022.csv')
prep_df <- read.csv('/projects/b1108/studies/mwmh/data/processed/neuroimaging/meta/fmriprep_10-06-2022.csv')

names(bids_df)[3:ncol(bids_df)] <- paste0('bids_', names(bids_df[, 3:ncol(bids_df)]))
names(prep_df)[3:ncol(prep_df)] <- paste0('prep_', names(prep_df[, 3:ncol(prep_df)]))

final_df <- merge(bids_df, prep_df)

##### All of these should be 0
sum(final_df$bids_t1w != final_df$prep_t1w) #0
sum(final_df$bids_rest != final_df$prep_rest) #2
sum(final_df$bids_avoid != final_df$prep_avoid) #2
sum(final_df$bids_faces != final_df$prep_faces) #2

##### Which are the culprit rows???
final_df[final_df$bids_rest != final_df$prep_rest, ]

# ^ Neither session of MWMH229 made it through fmriprep
