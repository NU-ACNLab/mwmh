### This script checks that all of the subjects/sessions that Anna has match the
### subjects/sessions that I have
###
### Ellyn Butler
### July 6, 2022

anna_df <- read.csv('/projects/b1108/studies/mwmh/data/raw/demographic/mwmh_struct_ids.csv')
ellyn_df <- read.csv('/projects/b1108/studies/mwmh/data/raw/demographic/bids_subsesids_07-06-2022.csv')


anna_df2 <- data.frame(matrix(ncol = 2, nrow = 0))
names(anna_df2) <- c('subid', 'sesid')

for (i in 1:nrow(anna_df)) {
  subid <- anna_df[i, 'SubjID']
  ses1 <- ifelse(anna_df[i, 'CV1'] == 1, TRUE, FALSE)
  ses2 <- ifelse(anna_df[i, 'CV2'] == 1, TRUE, FALSE)
  if (ses1 == TRUE) { anna_df2 <- rbind(anna_df2, data.frame(subid=subid, sesid=1)) }
  if (ses2 == TRUE) { anna_df2 <- rbind(anna_df2, data.frame(subid=subid, sesid=2)) }
}

anna_df2$anna <- 1
ellyn_df$ellyn <- 1

final_df <- merge(anna_df2, ellyn_df, all=TRUE)
final_df[is.na(final_df)] <- 0

################################# Anna Missing #################################

anna_missing <- final_df[final_df$anna == 0, ]
write.csv(anna_missing, paste0('/projects/b1108/studies/mwmh/data/raw/demographic/anna_missing_', Sys.Date(), '.csv'), row.names=FALSE)

################################# Ellyn Missing ################################

ellyn_missing <- final_df[final_df$ellyn == 0, ]
#write.csv(ellyn_missing, paste0('/projects/b1108/studies/mwmh/data/raw/demographic/ellyn_missing_', Sys.Date(), '.csv'), row.names=FALSE)

### Do I have the dicoms? Yes, but not in this dataframe. So what the hell happened here?
dicom_df <- read.csv('/projects/b1108/studies/mwmh/data/raw/neuroimaging/meta/params_2022-07-06.csv')
dicom_df$subid_sesid <- paste(dicom_df$subid, dicom_df$sesid, sep='_')
dicom_df2 <- dicom_df[match(unique(dicom_df$subid_sesid), dicom_df$subid_sesid),]
