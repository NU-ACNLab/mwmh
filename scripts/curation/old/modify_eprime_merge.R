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

# Change subject label from 302 to 320
subMWMH320_ses1_taskavoid_df[, 'Subject'] <- 320

#### 3.)
schedule_df[schedule_df$subid == 'MWMH376' & schedule_df$sesid == 1, ] #2017-04-03
subMWMH376_ses1_taskavoid_df[1, 'SessionDate'] #"2017-04-03"
# ^ These dates match

# Change subject label from 376 to 367
subMWMH376_ses1_taskavoid_df[, 'Subject'] <- 367

######## Check out sessions with conflicting sub ses labels on nurips #########

# MWMH114, 2, 2017-07-17
head(avoid_df[avoid_df$Subject == 114 & avoid_df$Session == 2, 'SessionDate']) #"2017-07-17"... Check
head(faces_df[faces_df$Subject == 114 & faces_df$Session == 2, 'SessionDate']) #"2017-07-17"... Check

# MWMH115, 2, 2017-06-05
head(avoid_df[avoid_df$Subject == 115 & avoid_df$Session == 2, 'SessionDate']) #"2017-06-05"... Check
head(faces_df[faces_df$Subject == 115 & faces_df$Session == 2, 'SessionDate']) #"2017-06-05"... Check

# MWMH121, 2, 2018-06-26
head(avoid_df[avoid_df$Subject == 121 & avoid_df$Session == 2, 'SessionDate']) #"2018-06-26"... Check
head(faces_df[faces_df$Subject == 121 & faces_df$Session == 2, 'SessionDate']) #"2018-06-26"... Check

# MWMH258, 2, 2018-08-27
head(avoid_df[avoid_df$Subject == 258 & avoid_df$Session == 2, 'SessionDate']) #"2018-08-27"... Check
head(faces_df[faces_df$Subject == 258 & faces_df$Session == 2, 'SessionDate']) #"2018-08-27"... Check

# MWMH304, 1, 2016-10-27... doesn't have task files, and doesn't have task imaging data
head(avoid_df[avoid_df$Subject == 304 & avoid_df$Session == 1, 'SessionDate'])
head(faces_df[faces_df$Subject == 304 & faces_df$Session == 1, 'SessionDate'])

# MWMH325, 1, 2016-11-21
head(avoid_df[avoid_df$Subject == 325 & avoid_df$Session == 1, 'SessionDate']) #"2016-11-21"... Check
head(faces_df[faces_df$Subject == 325 & faces_df$Session == 1, 'SessionDate']) #"2016-11-21"... Check

################################################################################


#### Merge back in sessions that original had to be excluded
faces_df <- rbind(faces_df, subMWMH298_ses2_taskfaces_df)
subMWMH320_ses1_taskavoid_df$RuntimeCapabilities <- NA
subMWMH320_ses1_taskavoid_df <- subMWMH320_ses1_taskavoid_df[, names(avoid_df)]
avoid_df <- rbind(avoid_df, subMWMH320_ses1_taskavoid_df)
avoid_df <- rbind(avoid_df, subMWMH376_ses1_taskavoid_df)

#### Create friendly subjects and session ids
# faces
for (sub in unique(faces_df$Subject)) {
  if (sub < 10) {
    faces_df[faces_df$Subject == sub, 'subid'] <- paste0('MWMH00', sub)
  } else if (sub < 100) {
    faces_df[faces_df$Subject == sub, 'subid'] <- paste0('MWMH0', sub)
  } else {
    faces_df[faces_df$Subject == sub, 'subid'] <- paste0('MWMH', sub)
  }
}
faces_df$sesid <- faces_df$Session
faces_df <- faces_df[, c('subid', 'sesid', names(faces_df)[!(faces_df %in% c('subid', 'sesid'))])]

# avoid
for (sub in unique(avoid_df$Subject)) {
  if (sub < 10) {
    avoid_df[avoid_df$Subject == sub, 'subid'] <- paste0('MWMH00', sub)
  } else if (sub < 100) {
    avoid_df[avoid_df$Subject == sub, 'subid'] <- paste0('MWMH0', sub)
  } else {
    avoid_df[avoid_df$Subject == sub, 'subid'] <- paste0('MWMH', sub)
  }
}
avoid_df$sesid <- avoid_df$Session
avoid_df <- avoid_df[, c('subid', 'sesid', names(avoid_df)[!(avoid_df %in% c('subid', 'sesid'))])]

#### Write out data, dated
write.csv(faces_df, paste0(base_dir, 'faces_', Sys.Date(), '.csv'), row.names=FALSE)
write.csv(avoid_df, paste0(base_dir, 'avoid_', Sys.Date(), '.csv'), row.names=FALSE)
