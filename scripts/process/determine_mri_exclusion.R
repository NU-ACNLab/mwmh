### This script determines who should be excluded from the final sample
### based off of movement parameters
###
### Ellyn Butler
### October 27, 2022 - October 28, 2022


qual_df <- read.csv('/projects/b1108/studies/mwmh/data/processed/neuroimaging/tabulated/quality_2022-10-25.csv')

qual_df[qual_df$task == 'rest', 'perc_trs_kept' <- qual_df[qual_df$task == 'rest', 'num_trs_kept']/1110
qual_df[qual_df$task == 'avoid', 'perc_trs_kept' <- qual_df[qual_df$task == 'avoid', 'num_trs_kept']/300
qual_df[qual_df$task == 'faces', 'perc_trs_kept' <- qual_df[qual_df$task == 'faces', 'num_trs_kept']/200

minutes_rest <- (1110*.555)/60
minutes_avoid <- (300*2)/60
minutes_faces <- (200*2)/60

qual_df$minutes_remaining <- NA
qual_df[qual_df$task == 'rest', 'minutes_remaining'] <- qual_df[qual_df$task == 'rest', 'perc_trs_kept']*minutes_rest
qual_df[qual_df$task == 'avoid', 'minutes_remaining'] <- qual_df[qual_df$task == 'avoid', 'perc_trs_kept']*minutes_avoid
qual_df[qual_df$task == 'faces', 'minutes_remaining'] <- qual_df[qual_df$task == 'faces', 'perc_trs_kept']*minutes_faces

qual_df$exclude <- ifelse(qual_df$minutes_remaining < 5, 1, 0)

table(qual_df$exclude)

table(qual_df[qual_df$sesid == 1, 'exclude'])
table(qual_df[qual_df$sesid == 2, 'exclude'])

qual_df$subid_sesid <- paste(qual_df$subid, qual_df$sesid, sep='_')

# Which sessions have at least one image excluded, and one not excluded?
exclude_sessions <- unique(qual_df[qual_df$exclude == 1, 'subid_sesid'])
keep_sessions <- unique(qual_df[qual_df$exclude == 0, 'subid_sesid'])

both <- exclude_sessions[exclude_sessions %in% keep_sessions]
