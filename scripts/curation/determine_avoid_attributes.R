### This script details attributes of the faces task critical to understanding it
###
### Ellyn Butler
### October 5, 2022

bidsdir = '/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/sub-MWMH241/ses-2/func/'
df <- read.table(paste0(bidsdir, 'sub-MWMH241_ses-2_task-avoid_events.tsv'), sep='\t', header=TRUE)

# Number of trials
max(df$trial)

# Mean and range of the duration of the cue
summary(df[df$cue == 1, 'duration'])

# Mean and range of the duration of the first fix
summary(df[df$fix1 == 1, 'duration'])

# Mean and range of the duration of the feedback
summary(df[df$feedback == 1, 'duration'])

# Mean and range of the duration of the second fix
summary(df[df$fix2 == 1, 'duration'])
