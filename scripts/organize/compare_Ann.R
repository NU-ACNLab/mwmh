### This script compares the subjects that Ann has from the first session of MWMH
### to the data I have gotten to make sure I am not missing anything
###
### Ellyn Butler
### May 3, 2022


ann_df <- read.csv('/projects/b1108/studies/mwmh/data/processed/neuroimaging/quality/MWMH_NUNDA_inclusionExclusion_ses-1.csv')
ellyn_df <- read.csv('/projects/b1108/studies/mwmh/data/raw/neuroimaging/meta/params_2022-04-20.csv')

ann_subids <- unique(ann_df$Subject)
ellyn_subids <- unique(ellyn_df$subid)

# Missing?

ann_subids[!(ann_subids %in% ellyn_subids)]
ellyn_subids[!(ellyn_subids %in% ann_subids)]
