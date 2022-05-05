### This script checks that the dates from the edat2 files match the dates
### from the MRI scheduling spreadsheet, and adjusts where there are conflicts
### to match the scheduling spreadsheet.
###
### Ellyn Butler
### May 4, 2022

base_dir <- '/projects/b1108/studies/mwmh/data/processed/neuroimaging/behavioral/combined/'

avoid_df <- read.csv(paste0(base_dir, 'task-avoid.csv'))
avoid_df$SessionDate <- as.Date(avoid_df$SessionDate, '%m/%d/%y')
faces_df <- read.csv(paste0(base_dir, 'task-faces.csv'))
faces_df$SessionDate <- as.Date(faces_df$SessionDate, '%m/%d/%y')

subMWMH298_ses2_taskfaces_df <- read.csv(paste0(base_dir, 'sub-MWMH298_ses-2_task-faces.csv'))
subMWMH298_ses2_taskfaces_df$SessionDate <- as.Date(subMWMH298_ses2_taskfaces_df$SessionDate, '%m/%d/%y')
subMWMH320_ses1_taskavoid_df <- read.csv(paste0(base_dir, 'sub-MWMH320_ses-1_task-avoid.csv'))
subMWMH320_ses1_taskavoid_df$SessionDate <- as.Date(subMWMH320_ses1_taskavoid_df$SessionDate, '%m/%d/%y')
subMWMH376_ses1_taskavoid_df <- read.csv(paste0(base_dir, 'sub-MWMH376_ses-1_task-avoid.csv'))
subMWMH376_ses1_taskavoid_df$SessionDate <- as.Date(subMWMH376_ses1_taskavoid_df$SessionDate, '%m/%d/%y')

schedule_df <- read.csv('/projects/b1108/studies/mwmh/data/raw/scheduling/scheduling.csv')
schedule_df$subid <- paste0('MWMH', schedule_df$subid)
schedule_df$mri_date <- as.Date(schedule_df$mri_date, '%m/%d/%y')

################ Check three with odd eprime sub and ses labels ################

#### 1.)
schedule_df[schedule_df$subid == 'MWMH298' & schedule_df$sesid == 2, ] #2018-09-15
subMWMH298_ses2_taskfaces_df[1, 'SessionDate'] #"2018-09-15"
# ^ These dates match

head(faces_df[faces_df$Subject == 298 & faces_df$Session == 2, 1:15])
# So the subject or session label is messed up in faces_df

# Who might this be?
schedule_df[schedule_df$mri_date %in% unique(faces_df[faces_df$Subject == 298 & faces_df$Session == 2, 'SessionDate']),]
# Looks like it is MWMH293 ses 2
faces_df[faces_df$Subject == 298 & faces_df$Session == 2, 'Subject'] <- 293

#### 2.)
schedule_df[schedule_df$subid == 'MWMH320' & schedule_df$sesid == 1, ] #2016-12-02
subMWMH320_ses1_taskavoid_df[1, 'SessionDate'] #"2016-12-02"
# ^ These dates match

head(avoid_df[avoid_df$Subject == 320 & avoid_df$Session == 1, 1:15])
# Looks like this subject isn't even in avoid_df. Not sure why E-Prime couldn't
# merge it

#### 3.)
schedule_df[schedule_df$subid == 'MWMH376' & schedule_df$sesid == 1, ] #2017-04-03
subMWMH376_ses1_taskavoid_df[1, 'SessionDate'] #"2017-04-03"
# ^ These dates match

head(avoid_df[avoid_df$Subject == 376 & avoid_df$Session == 1, 1:15])
# Looks like this subject isn't even in avoid_df. Not sure why E-Prime couldn't
# merge it

######## Check out sessions with conflicting sub ses labels on nurips #########




################################################################################


# Merge back in sessions that original had to be excluded


# Write out data, dated
