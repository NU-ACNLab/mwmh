### This script corrects the incorrect subject and session identifiers, and then
### combines the faces and the avoid data together to form two mega csvs.
### See `identify_sub_ses_discrepancies_eprime.R` for detective work.
###
### Ellyn Butler
### July 27, 2022 - July 28, 2022

base_dir <- '/projects/b1108/studies/mwmh/data/processed/neuroimaging/behavioral/'

cor_avoid_df <- read.csv(paste0(base_dir, 'correct_task-avoid_07-28-2022.csv'))
cor_faces_df <- read.csv(paste0(base_dir, 'correct_task-faces_07-28-2022.csv'))
in_avoid_df <- read.csv(paste0(base_dir, 'incorrect_task-avoid_07-27-2022.csv'))
in_faces_df <- read.csv(paste0(base_dir, 'incorrect_task-faces_07-27-2022.csv'))

################################ Correct labels ################################

### 1)
in_avoid_df[in_avoid_df$Subject == 302 & in_avoid_df$Session == 1, 'Subject'] <- 320

### 2)
in_faces_df[in_faces_df$Subject == 274 & in_faces_df$Session == 1, 'Session'] <- 2

### 3)
in_faces_df[in_faces_df$Subject == 298 & in_faces_df$Session == 2, 'Subject'] <- 293

### 4)
in_avoid_df[in_avoid_df$Subject == 106 & in_avoid_df$Session == 1, 'Session'] <- 2

### 5)
in_avoid_df[in_avoid_df$Subject == 288 & in_avoid_df$Session == 1, 'Subject'] <- 236
in_faces_df[in_faces_df$Subject == 288 & in_faces_df$Session == 1, 'Subject'] <- 236

### 6)
in_avoid_df[in_avoid_df$Subject == 137 & in_avoid_df$Session == 1, 'Session'] <- 2
in_faces_df[in_faces_df$Subject == 137 & in_faces_df$Session == 1, 'Session'] <- 2

### 7)
in_avoid_df[in_avoid_df$Subject == 135 & in_avoid_df$Session == 1, 'Session'] <- 2
in_faces_df[in_faces_df$Subject == 135 & in_faces_df$Session == 1, 'Session'] <- 2

### 8)
in_avoid_df[in_avoid_df$Subject == 290 & in_avoid_df$Session == 1, 'Subject'] <- 311
in_faces_df[in_faces_df$Subject == 290 & in_faces_df$Session == 1, 'Subject'] <- 311

### 9)
in_avoid_df[in_avoid_df$Subject == 367 & in_avoid_df$Session == 1, 'Subject'] <- 376
in_faces_df[in_faces_df$Subject == 367 & in_faces_df$Session == 1, 'Subject'] <- 376

### 10)
in_avoid_df[in_avoid_df$Subject == 131 & in_avoid_df$Session == 1, 'Session'] <- 2
in_faces_df[in_faces_df$Subject == 131 & in_faces_df$Session == 1, 'Session'] <- 2


############################### Merge and export ###############################

avoid_df <- rbind(cor_avoid_df, in_avoid_df)
faces_df <- rbind(cor_faces_df, in_faces_df)

#### Create friendly subjects and session ids
# faces
faces_df$subid <- NA
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
faces_df <- faces_df[, c('subid', 'sesid', names(faces_df)[!(names(faces_df) %in% c('subid', 'sesid'))])]

# avoid
avoid_df$subid <- NA
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
avoid_df <- avoid_df[, c('subid', 'sesid', names(avoid_df)[!(names(avoid_df) %in% c('subid', 'sesid'))])]

#### Write out data, dated
write.csv(faces_df, paste0(base_dir, 'faces_', Sys.Date(), '.csv'), row.names=FALSE)
write.csv(avoid_df, paste0(base_dir, 'avoid_', Sys.Date(), '.csv'), row.names=FALSE)
