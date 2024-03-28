### This script determines problems with the passive avoidance task
###
### Ellyn Butler
### October 5, 2022

base_path <- '/projects/b1108/studies/mwmh/data/processed/neuroimaging/behavioral/'

avoid_df <- read.csv(paste0(base_path, 'avoid_2022-07-28.csv'))


############################## Always gain or lose #############################

table(avoid_df$Feedbk)
sum(is.na(avoid_df$Feedbk))

mwmh270_df <- avoid_df[which(avoid_df$subid == 'MWMH270' & avoid_df$sesid == 2), ]
mwmh270_df[which(mwmh270_df$Trial %in% 10:12), c('Trial', 'Stm.RT', 'Stm.RESP', 'Amount', 'Feedbk', 'Message')]
# ^ Hopefully the 'Message' column is the one they saw

########################### Shapes predict outcome? ############################
