### This script checks if there is behavioral data for every task fmri sequence
###
### Ellyn Butler
### March 8, 2022

fmri_df <- read.csv('/projects/b1108/studies/mwmh/data/raw/neuroimaging/meta/params_2022-03-10.csv')
behav_df <- read.csv('/projects/b1108/studies/mwmh/data/raw/neuroimaging/meta/task_behav.csv')

avoid_df <- fmri_df[!is.na(fmri_df$ProtocolName) & !is.na(fmri_df$SequenceName)
                    & fmri_df$NDicoms > 295 & fmri_df$NDicoms < 305
                    & (fmri_df$ProtocolName %in% c('PASSIVE', 'PASSIVE_AVOIDANCE') |
                    fmri_df$ProtocolName == 'MB2_task_20_70_2000_1pt7iso'), ]
faces_df <- fmri_df[!is.na(fmri_df$ProtocolName) & !is.na(fmri_df$SequenceName)
                    & fmri_df$NDicoms > 195 & fmri_df$NDicoms < 205
                    & (fmri_df$ProtocolName == 'FACES' |
                    fmri_df$ProtocolName == 'MB2_task_20_70_2000_1pt7iso'), ]


avoid_df$fmri_avoid <- 1
faces_df$fmri_faces <- 1

avoid_df <- avoid_df[, c('subid', 'sesid', 'fmri_avoid')]
faces_df <- faces_df[, c('subid', 'sesid', 'fmri_faces')]

names(behav_df) <- c('subid', 'sesid', 'behav_faces', 'behav_avoid')

final_df <- merge(behav_df, avoid_df, all=TRUE)
final_df <- merge(final_df, faces_df, all=TRUE)

final_df$fmri_faces[is.na(final_df$fmri_faces)] <- 0
final_df$fmri_avoid[is.na(final_df$fmri_avoid)] <- 0

sum_df <- data.frame(task=c(rep('avoid', 4), rep('faces', 4)),
                     behav_exists=rep(c('Yes', 'Yes', 'No', 'No'), 2),
                     fmri_exists=rep(c('Yes', 'No', 'Yes', 'No'), 2),
                     N=c(nrow(final_df[final_df$behav_avoid %in% 1 & final_df$fmri_avoid %in% 1, ]),
                        nrow(final_df[final_df$behav_avoid %in% 1 & final_df$fmri_avoid %in% 0, ]),
                        nrow(final_df[final_df$behav_avoid %in% 0 & final_df$fmri_avoid %in% 1, ]),
                        nrow(final_df[final_df$behav_avoid %in% 0 & final_df$fmri_avoid %in% 0, ]),
                        nrow(final_df[final_df$behav_faces %in% 1 & final_df$fmri_faces %in% 1, ]),
                        nrow(final_df[final_df$behav_faces %in% 1 & final_df$fmri_faces %in% 0, ]),
                        nrow(final_df[final_df$behav_faces %in% 0 & final_df$fmri_faces %in% 1, ]),
                        nrow(final_df[final_df$behav_faces %in% 0 & final_df$fmri_faces %in% 0, ]))
                        )

write.csv(sum_df, paste0('/projects/b1108/studies/mwmh/data/raw/neuroimaging/meta/behav_fmri_match_summary_', Sys.Date(), '.csv'), row.names=FALSE)
write.csv(final_df, paste0('/projects/b1108/studies/mwmh/data/raw/neuroimaging/meta/behav_fmri_match_', Sys.Date(), '.csv'), row.names=FALSE)
