### This script calculates age at assessment visit and MRI visit for all subjects
### at both time points
###
### Ellyn Butler
### July 19, 2022 - November 7, 2022

# NOTE: This raw data is not on Quest because it is PHI

# TO DO: Make sure all the subject and session identifiers match up with the final
# sample (e.g., after QA)





dob_df <- read.csv('/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/raw/demographic/MWMH_V1_DOB.csv')
dob_df <- dob_df[!is.na(dob_df$ID), ]
v1_df <- read.csv('/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/raw/demographic/V1_Dates.csv')
v1_df <- v1_df[!is.na(v1_df$ID), ]
v2_df <- read.csv('/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/raw/demographic/V2_Dates.csv')
v2_df <- v2_df[!is.na(v2_df$ID), ]

# Insert dates that are missing from these csvs, but can be found in dicom headers
v2_df[v2_df$ID == 133, 'DOV_MRI_V2'] <- '1/26/19'
v2_df[v2_df$ID == 370, 'DOV_MRI_V2'] <- '2/21/19'

# Convert into dates
names(dob_df) <- c('subid', 'dob')
dob_df$subid <- paste0('MWMH', dob_df$subid)
dob_df$dob <- as.Date(dob_df$dob, '%m/%d/%Y')

names(v1_df) <- c('subid', 'dov_lab', 'dov_mri')
v1_df$subid <- paste0('MWMH', v1_df$subid)
v1_df$sesid <- 1
v1_df$dov_lab <- as.Date(v1_df$dov_lab, '%m/%d/%y')
v1_df$dov_mri <- as.Date(v1_df$dov_mri, '%m/%d/%y')

names(v2_df) <- c('subid', 'dov_lab', 'dov_mri')
v2_df$subid <- paste0('MWMH', v2_df$subid)
v2_df$sesid <- 2
v2_df$dov_lab <- as.Date(v2_df$dov_lab, '%m/%d/%y')
v2_df$dov_mri <- as.Date(v2_df$dov_mri, '%m/%d/%y')

visit_df <- rbind(v1_df, v2_df)

final_df <- merge(visit_df, dob_df, by='subid', all=TRUE)
final_df <- final_df[, c('subid', 'sesid', 'dob', 'dov_lab', 'dov_mri')]

final_df$age_lab <- as.numeric((final_df$dov_lab - final_df$dob)/365.25)
final_df$age_mri <- as.numeric((final_df$dov_mri - final_df$dob)/365.25)
final_df$days_mri_minus_lab <- as.numeric(final_df$dov_mri - final_df$dov_lab)


write.csv(final_df, paste0('/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/demographic/dob_dov_', Sys.Date(), '.csv'), row.names=FALSE)

quest_df <- final_df[, c('subid', 'sesid', 'dov_lab', 'dov_mri', 'age_lab', 'age_mri', 'days_mri_minus_lab')]
write.csv(quest_df, paste0('/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/demographic/age_visits_', Sys.Date(), '.csv'), row.names=FALSE)


##### Basic description of dates of visits

# Among sessions where subjects had both lab and mri visits...
complete_df <- final_df[!is.na(final_df$days_mri_minus_lab), ]
numses <- nrow(complete_df) #490

# What percent of sessions had mri performed after the lab? 76.94%
mri_b4_lab_df <- complete_df[complete_df$days_mri_minus_lab > 0, ]
mri_b4_lab_numses <- nrow(mri_b4_lab_df)
mri_b4_lab_numses/numses

# What percent of sessions had mri performed on the same day as the lab? 16.73%
mri_same_lab_df <- complete_df[complete_df$days_mri_minus_lab == 0, ]
mri_same_lab_numses <- nrow(mri_same_lab_df)
mri_same_lab_numses/numses

# What percent of sessions had mri performed after the lab? 6.33%
mri_aft_lab_df <- complete_df[complete_df$days_mri_minus_lab < 0, ]
mri_aft_lab_numses <- nrow(mri_aft_lab_df)
mri_aft_lab_numses/numses

# What is the average number of days that the mri comes after the lab session? 22.52
mean(complete_df$days_mri_minus_lab)

# Descriptive statistics for age at the mri visit
summary(complete_df[complete_df$sesid == 1, 'age_mri']) #min=11.88, med=13.95, mean=13.96, max=15.34
summary(complete_df[complete_df$sesid == 2, 'age_mri']) #min=13.93, med=15.98, mean=16.00, max=17.25









#
