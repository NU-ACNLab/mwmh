### This script corrects the incorrect subject identifiers in the E-Prime edat2
### files that got exported to csv using E-Merge and then E-DataAid
### NOTE: It is more than possible mistakes were missed. The only reason these
### three were caught is because E-Merge threw an error because the subject
### identifier was modified to be identical to another subject's identifier
### (e.g. 320 was changed to 302)
###
### Ellyn Butler
### April 7, 2022

basepath <- '~/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/behavioral/combined/'

# MILLER_FACES_fMRI-298-2.edat2 (got subject identifier correct)
# MILLER_PA_fMRI-320-1.edat2 (says Subject 302)
# MILLER_PA_fMRI-376-1.edat2 (says Subject 367)
# “Warning: If you merge this file, your target file will contain one or more
# sessions with the same subject number, session number, and experiment name”

avoid_df <- read.csv(paste0(basepath, 'task-avoid.csv'))
faces_df <- read.csv(paste0(basepath, 'task-faces.csv'))

################################################################################

# Does faces_df contain a sub-298_ses-2? If so, this is probably actually
# sub-289, but double check with neuroimaging data to confirm this subject
# in fact exists ==> It does contain sub-298_ses-2 and sub-289 (ses 1 and 2)
# exists in neuroimaging, but sub-298_ses-2 already exists in faces_df (but
# ses 1 does not... but Ajay gave me this data) NOT CLEAR WHAT IS GOING ON
# HERE... maybe ses label is incorrect? Nope. MILLER_FACES_fMRI-298-2.txt has
# Session set to 2

#faces_df[faces_df$Subject == 298 & faces_df$Session == 2, 'Subject'] <- 289

# Load in the true sub-MWMH298_ses-2_task-faces, merge with faces_df, and export
#sub-MWMH298_ses-2_task-faces_df <- read.csv(paste0(basepath, 'sub-MWMH298_ses-2_task-faces.csv'))

#faces_df <- rbind(faces_df, sub-MWMH298_ses-2_task-faces_df)

#write.csv(faces_df, paste0(basepath, 'task-faces_final.csv'), row.names=FALSE)

################################################################################
