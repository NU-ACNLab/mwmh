### This script turns eprime task response and task design information into
### a tsv compliant with BIDS
###
### Ellyn Butler
### March 29, 2022

library('stringr')
library('ggplot2')

# TO DO: Turn these into command line arguments for job submission
sub = 379
ses = 1

base_path <- '~/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/behavioral/'


#################################### Avoid ####################################

avoid_df <- read.csv(paste0(base_path, 'combined/task-avoid.csv'))
avoid_df <- avoid_df[avoid_df$Subject %in% sub & avoid_df$Session %in% ses, ]
row.names(avoid_df) <- 1:nrow(avoid_df)

########## Times
#head(avoid_df[, c('Stm.OnsetTime', 'Fixation.OnsetTime',
#            'Fixation.OnsetToOnsetTime', 'Stm.OnsetToOnsetTime',
#            'Stm.RT')])

### Length of Cue Phase (Should be: 1500, Found: ~ 1485)
# Onset of Cue Phase: 'Stm.OnsetTime'?
#avoid_df$Fixation.OnsetTime - avoid_df$Stm.OnsetTime

### Length of First Fixation (Should be: 500-2500, Found: 501-2519)
# Onset of First Fixation: 'Fixation.OnsetTime'?
#avoid_df$Fixation.OnsetToOnsetTime #What actually happened?
# OR (not equal!!! but very close)
#avoid_df$Jit1 #What was supposed to happen?

### Length of Feedback Phase (Should be: 1500, Found: ~ 1485)
# Onset of Feedback Phase: 'Fixation.OnsetTime' + 'Fixation.OnsetToOnsetTime'?
#avoid_df$Stm.OnsetToOnsetTime

### Length of Second Fixation (Should be: 0-4000, Found: )
# Onset of Second Fixation: 'Stm.OnsetToOnsetTime' + 'Fixation.OnsetTime' + 'Fixation.OnsetToOnsetTime'
#avoid_df$Jit2 #? There should be a less perfect version of this, and odd increasing
# Alternatively, use the different of the onset for the second fixation and the
# onset of the subsequent cue... but don't know length of very last fix2 that way
# (just put in value for Jit2 - but Jit2's don't line up well...)
fix2_dur <- c(avoid_df[2:nrow(avoid_df), 'Stm.OnsetTime'] - (avoid_df[1:(nrow(avoid_df) - 1),
  'Stm.OnsetToOnsetTime'] + avoid_df[1:(nrow(avoid_df) - 1), 'Fixation.OnsetTime'] +
  avoid_df[1:(nrow(avoid_df) - 1), 'Fixation.OnsetToOnsetTime']),
  avoid_df[nrow(avoid_df), 'Jit2'])

eprime_to_pulse <- avoid_df[1, 'Stm.OnsetTime'] - 12000
#eprime_to_pulse <- 0 #TMP

# NOTE: First onset time seems suspiciously late
time_df <- data.frame(onset_cue=(avoid_df$Stm.OnsetTime - eprime_to_pulse)/1000,
            duration_cue=(avoid_df$Fixation.OnsetTime - avoid_df$Stm.OnsetTime)/1000,
            onset_fix1=(avoid_df$Fixation.OnsetTime - eprime_to_pulse)/1000,
            duration_fix1=(avoid_df$Fixation.OnsetToOnsetTime)/1000,
            onset_feedback=(avoid_df$Fixation.OnsetTime + avoid_df$Fixation.OnsetToOnsetTime - eprime_to_pulse)/1000,
            duration_feedback=(avoid_df$Stm.OnsetToOnsetTime)/1000,
            onset_fix2=(avoid_df$Stm.OnsetToOnsetTime + avoid_df$Fixation.OnsetTime + avoid_df$Fixation.OnsetToOnsetTime - eprime_to_pulse)/1000,
            duration_fix2=fix2_dur/1000)
            # ^ duration_fix2 is correct here

avoid_df <- cbind(avoid_df, time_df)

final_avoid_df <- data.frame(subid=rep(paste0('MWMH', sub), nrow(avoid_df)*4),
                       sesid=rep(ses, nrow(avoid_df)*4),
                       onset=NA, duration=NA, trial=NA, cue=NA, fix1=NA,
                       feedback=NA, fix2=NA, approach=NA, avoid=NA,
                       reward=NA, loss=NA, nothing=NA, gain50=NA, gain10=NA,
                       lose10=NA, lose50=NA)

########## Stimuli

#onset,duration,trial,cue,fix1,feedback,fix2,approach,avoid,reward,loss,nothing

j=0
for (i in 1:nrow(avoid_df)) {
  # onset
  final_avoid_df[i+j, 'onset'] <- avoid_df[i, 'onset_cue']
  final_avoid_df[i+j+1, 'onset'] <- avoid_df[i, 'onset_fix1']
  final_avoid_df[i+j+2, 'onset'] <- avoid_df[i, 'onset_feedback']
  final_avoid_df[i+j+3, 'onset'] <- avoid_df[i, 'onset_fix2']
  # duration
  final_avoid_df[i+j, 'duration'] <- avoid_df[i, 'duration_cue']
  final_avoid_df[i+j+1, 'duration'] <- avoid_df[i, 'duration_fix1']
  final_avoid_df[i+j+2, 'duration'] <- avoid_df[i, 'duration_feedback']
  final_avoid_df[i+j+3, 'duration'] <- avoid_df[i, 'duration_fix2']
  # trial
  final_avoid_df[(i+j):(i+j+3), 'trial'] <- avoid_df[i, 'Trial']
  # cue - is a cue event or not
  final_avoid_df[(i+j):(i+j+3), 'cue'] <- c(1, 0, 0, 0)
  # fix1 - is a fix1 event or not
  final_avoid_df[(i+j):(i+j+3), 'fix1'] <- c(0, 1, 0, 0)
  # feedback - is a feedback event or not
  final_avoid_df[(i+j):(i+j+3), 'feedback'] <- c(0, 0, 1, 0)
  # fix2 - is a fix1 event or not
  final_avoid_df[(i+j):(i+j+3), 'fix2'] <- c(0, 0, 0, 1)
  # approach - cue & press
  press <- as.numeric(avoid_df[i, 'Stm.RT'] > 0)
  final_avoid_df[i+j, 'approach'] <- press*final_avoid_df[i+j, 'cue']
  final_avoid_df[i+j+1, 'approach'] <- press*final_avoid_df[i+j+1, 'cue']
  final_avoid_df[i+j+2, 'approach'] <- press*final_avoid_df[i+j+2, 'cue']
  final_avoid_df[i+j+3, 'approach'] <- press*final_avoid_df[i+j+3, 'cue']
  # avoid - cue & no press
  final_avoid_df[i+j, 'avoid'] <- (1-press)*final_avoid_df[i+j, 'cue']
  final_avoid_df[i+j+1, 'avoid'] <- (1-press)*final_avoid_df[i+j+1, 'cue']
  final_avoid_df[i+j+2, 'avoid'] <- (1-press)*final_avoid_df[i+j+2, 'cue']
  final_avoid_df[i+j+3, 'avoid'] <- (1-press)*final_avoid_df[i+j+3, 'cue']
  # reward - feedback & reward ($ > 0)
  final_avoid_df[i+j, 'reward'] <- (avoid_df[i, 'Amount'] > 0)*final_avoid_df[i+j, 'feedback']
  final_avoid_df[i+j+1, 'reward'] <- (avoid_df[i, 'Amount'] > 0)*final_avoid_df[i+j+1, 'feedback']
  final_avoid_df[i+j+2, 'reward'] <- (avoid_df[i, 'Amount'] > 0)*final_avoid_df[i+j+2, 'feedback']
  final_avoid_df[i+j+3, 'reward'] <- (avoid_df[i, 'Amount'] > 0)*final_avoid_df[i+j+3, 'feedback']
  # loss - feedback & loss ($ < 0)
  final_avoid_df[i+j, 'loss'] <- (avoid_df[i, 'Amount'] < 0)*final_avoid_df[i+j, 'feedback']
  final_avoid_df[i+j+1, 'loss'] <- (avoid_df[i, 'Amount'] < 0)*final_avoid_df[i+j+1, 'feedback']
  final_avoid_df[i+j+2, 'loss'] <- (avoid_df[i, 'Amount'] < 0)*final_avoid_df[i+j+2, 'feedback']
  final_avoid_df[i+j+3, 'loss'] <- (avoid_df[i, 'Amount'] < 0)*final_avoid_df[i+j+3, 'feedback']
  # nothing - feedback & $0
  final_avoid_df[i+j, 'nothing'] <- (avoid_df[i, 'Amount'] == 0)*final_avoid_df[i+j, 'feedback']
  final_avoid_df[i+j+1, 'nothing'] <- (avoid_df[i, 'Amount'] == 0)*final_avoid_df[i+j+1, 'feedback']
  final_avoid_df[i+j+2, 'nothing'] <- (avoid_df[i, 'Amount'] == 0)*final_avoid_df[i+j+2, 'feedback']
  final_avoid_df[i+j+3, 'nothing'] <- (avoid_df[i, 'Amount'] == 0)*final_avoid_df[i+j+3, 'feedback']
  # gain 50
  final_avoid_df[i+j, 'gain50'] <- (avoid_df[i, 'Amount'] == 50)*final_avoid_df[i+j, 'feedback']
  final_avoid_df[i+j+1, 'gain50'] <- (avoid_df[i, 'Amount'] == 50)*final_avoid_df[i+j+1, 'feedback']
  final_avoid_df[i+j+2, 'gain50'] <- (avoid_df[i, 'Amount'] == 50)*final_avoid_df[i+j+2, 'feedback']
  final_avoid_df[i+j+3, 'gain50'] <- (avoid_df[i, 'Amount'] == 50)*final_avoid_df[i+j+3, 'feedback']
  # gain 10
  final_avoid_df[i+j, 'gain10'] <- (avoid_df[i, 'Amount'] == 10)*final_avoid_df[i+j, 'feedback']
  final_avoid_df[i+j+1, 'gain10'] <- (avoid_df[i, 'Amount'] == 10)*final_avoid_df[i+j+1, 'feedback']
  final_avoid_df[i+j+2, 'gain10'] <- (avoid_df[i, 'Amount'] == 10)*final_avoid_df[i+j+2, 'feedback']
  final_avoid_df[i+j+3, 'gain10'] <- (avoid_df[i, 'Amount'] == 10)*final_avoid_df[i+j+3, 'feedback']
  # lose 10
  final_avoid_df[i+j, 'lose10'] <- (avoid_df[i, 'Amount'] == -10)*final_avoid_df[i+j, 'feedback']
  final_avoid_df[i+j+1, 'lose10'] <- (avoid_df[i, 'Amount'] == -10)*final_avoid_df[i+j+1, 'feedback']
  final_avoid_df[i+j+2, 'lose10'] <- (avoid_df[i, 'Amount'] == -10)*final_avoid_df[i+j+2, 'feedback']
  final_avoid_df[i+j+3, 'lose10'] <- (avoid_df[i, 'Amount'] == -10)*final_avoid_df[i+j+3, 'feedback']
  # lose 50
  final_avoid_df[i+j, 'lose50'] <- (avoid_df[i, 'Amount'] == -50)*final_avoid_df[i+j, 'feedback']
  final_avoid_df[i+j+1, 'lose50'] <- (avoid_df[i, 'Amount'] == -50)*final_avoid_df[i+j+1, 'feedback']
  final_avoid_df[i+j+2, 'lose50'] <- (avoid_df[i, 'Amount'] == -50)*final_avoid_df[i+j+2, 'feedback']
  final_avoid_df[i+j+3, 'lose50'] <- (avoid_df[i, 'Amount'] == -50)*final_avoid_df[i+j+3, 'feedback']
  j=j+3
}

bids_path <- '~/Documents/Northwestern/studies/mwmh/data/raw/neuroimaging/bids/sub-MWMH'

# SANITY CHECK: Does the onset time of the i+1 row equal the onset + duration of i?
sanity <- final_avoid_df[2:nrow(final_avoid_df), 'onset'] - (final_avoid_df[1:(nrow(final_avoid_df) - 1),'onset'] + final_avoid_df[1:(nrow(final_avoid_df) - 1), 'duration']) < .00001

if (FALSE %in% sanity) {
  stop('The onsets and durations are not matching up')
}

# Write out tsv to bids directory
write.table(final_avoid_df, paste0(bids_path, sub, '/ses-', ses, '/func/sub-MWMH',
  sub, '_ses-', ses, '_task-avoid.tsv'), row.names=FALSE, sep='\t')

# final_avoid_df should have 96*4 = 384 rows



#### Questions
# 1. Is Stm.OnsetToOnsetTime or Fixation.OnsetToOnsetTime the length of the
#    cue phase? Length of the feedback phase?

#### Notes
# 1. avoid_df$Stm.DurationError = - avoid_df$Stm.OnsetDelay
# 2. avoid_df$Stm.OnsetToOnsetTime == avoid_df$Fixation.OnsetToOnsetTime (FALSE)
# 3. avoid_df$Stm.OnsetTime < avoid_df$Fixation.OnsetTime + avoid_df$Fixation.OnsetToOnsetTime
#    (TRUE) ==> The latter is the onset time of the Feedback Phase
# 4. Jit1 and Jit2 are different
# 5. Jit2 is monotonically non-decreasing
# 6. Stm.RTTime (time that they reacted) and Stm.RT (how long it took them to
#    react to the stimulus)

#################################### Faces ####################################

faces_df <- read.csv(paste0(base_path, 'combined/task-faces.csv'))

# ImageDisplay2.RESP is wonky. It should just be 1's (response is female) and
# 2's (response is male), but it also has 3's and 4's, almost in equal measure.
# The question is, what gender response do the 1's, 2's, 3's and 4's correspond to?
# And is it the same across every subject?

onetwo_df <- faces_df[faces_df$ImageDisplay2.RESP %in% c(1, 2), c('gender', 'ImageDisplay2.RESP')]
cor(onetwo_df$ImageDisplay2.RESP, onetwo_df$gender) #.80
# ^ Indicates that 1's mean female response in 'ImageDisplay2.RESP', but corr is
# suspiciously low, considering this should be a very easy question to get right

threefour_df <- faces_df[faces_df$ImageDisplay2.RESP %in% c(3, 4), c('gender', 'ImageDisplay2.RESP')]
cor(threefour_df$ImageDisplay2.RESP, threefour_df$gender) # -.82
# ^ Indicates that 4's mean female response in 'ImageDisplay2.RESP', but corr is
# suspiciously low, considering this should be a very easy question to get right

# So what are the correlations within subjects?
within_df <- data.frame(sub_ses=unique(paste0(faces_df$Subject, '_', faces_df$Session)),
                      onestwos=NA,
                      corr=NA,
                      num_NA=NA
                    )

for (i in 1:nrow(within_df)) {
  sub <- as.numeric(strsplit(within_df[i, 'sub_ses'], '_')[[1]][1])
  ses <- as.numeric(strsplit(within_df[i, 'sub_ses'], '_')[[1]][2])
  ss_df <- faces_df[faces_df$Subject == sub & faces_df$Session == ses , c('gender', 'ImageDisplay2.RESP')]
  ss_df <- ss_df[2:(nrow(ss_df)-1), ]
  if (1 %in% ss_df$ImageDisplay2.RESP & !(4 %in% ss_df$ImageDisplay2.RESP)) {
    within_df[i, 'onestwos'] <- TRUE
    within_df[i, 'corr'] <- cor(ss_df$ImageDisplay2.RESP, ss_df$gender, use='complete.obs')
  }
  if (4 %in% ss_df$ImageDisplay2.RESP & !(1 %in% ss_df$ImageDisplay2.RESP)) {
    within_df[i, 'onestwos'] <- FALSE
    within_df[i, 'corr'] <- cor(ss_df$ImageDisplay2.RESP, ss_df$gender, use='complete.obs')
  }
  if (1 %in% ss_df$ImageDisplay2.RESP & 4 %in% ss_df$ImageDisplay2.RESP) {
      print(paste0('sub ', sub, 'ses ', ses, ' OH SHIT. Both 1s and 2s are in the RESP column.'))
  }
  within_df[i, 'num_NA'] <- sum(is.na(ss_df$ImageDisplay2.RESP))
}

# One person who didn't respond at all, filter out
within_df <- within_df[!is.na(within_df$corr), ]
within_df$onestwos <- factor(within_df$onestwos, levels = c(TRUE, FALSE),
                  labels = c('Responses 1s and 2s', 'Responses 3s and 4s')
                  )
genderresp_plot <- ggplot(within_df, aes(x=corr)) + theme_linedraw() +
  geom_histogram() + facet_grid(~ onestwos) + xlab('Correlation between gender and response within subject') +
  ggtitle('Correlation between gender (1 - female, 2 - male) and identification of gender (1, 2, 3, 4)')


pdf('/Users/flutist4129/Documents/Northwestern/studies/mwmh/plots/genderresps.pdf', width=8, height=6)
genderresp_plot
dev.off()

# Now do the real analysis and just select the one subject
faces_df <- faces_df[faces_df$Subject %in% sub & faces_df$Session %in% ses, ]
faces_df <- faces_df[2:(nrow(faces_df)-1), ] # NOT SURE IF APPROPRIATE, but first and last rows have mostly NAs
row.names(faces_df) <- 1:nrow(faces_df)


eprime_to_pulse <- faces_df[1, 'ImageDisplay2.OnsetTime'] - 14500 # THIS MIGHT BE CORRECT - SUSPICIOUS NA FIRST ROW

fix_dur <- c(faces_df[2:nrow(faces_df), 'ImageDisplay2.OnsetTime'] -
  (faces_df[1:(nrow(faces_df)-1), 'Blank.OnsetTime'] + faces_df[1:(nrow(faces_df)-1),
  'Blank.OnsetToOnsetTime']), avoid_df[nrow(faces_df), 'Jit1'])

time_df <- data.frame(onset_face=(faces_df$ImageDisplay2.OnsetTime - eprime_to_pulse)/1000,
            duration_face=(faces_df$Blank.OnsetTime - faces_df$ImageDisplay2.OnsetTime)/1000,
            onset_blank=(faces_df$Blank.OnsetTime - eprime_to_pulse)/1000,
            duration_blank=(faces_df$Blank.OnsetToOnsetTime)/1000,
            onset_fix=(faces_df$Jitter1.OnsetTime - eprime_to_pulse)/1000,
            duration_fix=fix_dur/1000
          )

faces_df <- cbind(faces_df, time_df)

#subid,sesid,onset,duration,trial,face,blank,fix,female,happy,intensity10,intensity20,intensity30,intensity40,intensity50,correct
# TO DO: Is 1 or 2 correct? Need to check eprime files
# TO DO: Is 1 or 2 female?

final_faces_df <- data.frame(subid=rep(paste0('MWMH', sub), nrow(faces_df)*3),
                        sesid=rep(ses, nrow(faces_df)*3),
                        onset=NA, duration=NA, trial=NA, face=NA, blank=NA,
                        fix=NA, female=NA, happy=NA, intensity10=NA,
                        intensity20=NA, intensity30=NA, intensity40=NA,
                        intensity50=NA, correct=NA)



#
j=0
for (i in 1:nrow(faces_df)) {
  # onset
  final_faces_df[i+j, 'onset'] <- faces_df[i, 'onset_face']
  final_faces_df[i+j+1, 'onset'] <- faces_df[i, 'onset_blank']
  final_faces_df[i+j+2, 'onset'] <- faces_df[i, 'onset_fix']
  # duration
  final_faces_df[i+j, 'duration'] <- faces_df[i, 'duration_face']
  final_faces_df[i+j+1, 'duration'] <- faces_df[i, 'duration_blank']
  final_faces_df[i+j+2, 'duration'] <- faces_df[i, 'duration_fix']
  # trial
  final_faces_df[(i+j):(i+j+2), 'trial'] <- faces_df[i, 'Trial']
  # face - is a face event or not
  final_faces_df[(i+j):(i+j+2), 'face'] <- c(1, 0, 0)
  # blank - is a blank screen or not
  final_faces_df[(i+j):(i+j+2), 'blank'] <- c(0, 1, 0)
  # fix - is a fixation cross or not
  final_faces_df[(i+j):(i+j+2), 'fix'] <- c(0, 0, 1)
  # female - (1) face is female (0) not female (could either be male, or not a face)
  final_faces_df[i+j, 'female'] <- (faces_df[i, 'gender'] == 1)*final_faces_df[i+j, 'face']
  final_faces_df[i+j+1, 'female'] <- (faces_df[i, 'gender'] == 1)*final_faces_df[i+j+1, 'face']
  final_faces_df[i+j+2, 'female'] <- (faces_df[i, 'gender'] == 1)*final_faces_df[i+j+2, 'face']
  # happy - (1) face is happy (0) not happy (could either be angry, or not a face)
  final_faces_df[i+j, 'happy'] <- (faces_df[i, 'emotion'] == 'Happy')*final_faces_df[i+j, 'face']
  final_faces_df[i+j+1, 'happy'] <- (faces_df[i, 'emotion'] == 'Happy')*final_faces_df[i+j+1, 'face']
  final_faces_df[i+j+2, 'happy'] <- (faces_df[i, 'emotion'] == 'Happy')*final_faces_df[i+j+2, 'face']
  # intensity10 - (1) face emotional intensity is 10 (0) item is either not a face, or a face with a different emotional intensity
  final_faces_df[i+j, 'intensity10'] <- (faces_df[i, 'intensity'] == 10)*final_faces_df[i+j, 'face']
  final_faces_df[i+j+1, 'intensity10'] <- (faces_df[i, 'intensity'] == 10)*final_faces_df[i+j+1, 'face']
  final_faces_df[i+j+2, 'intensity10'] <- (faces_df[i, 'intensity'] == 10)*final_faces_df[i+j+2, 'face']
  # intensity20 ^
  final_faces_df[i+j, 'intensity20'] <- (faces_df[i, 'intensity'] == 20)*final_faces_df[i+j, 'face']
  final_faces_df[i+j+1, 'intensity20'] <- (faces_df[i, 'intensity'] == 20)*final_faces_df[i+j+1, 'face']
  final_faces_df[i+j+2, 'intensity20'] <- (faces_df[i, 'intensity'] == 20)*final_faces_df[i+j+2, 'face']
  # intensity30 ^
  final_faces_df[i+j, 'intensity30'] <- (faces_df[i, 'intensity'] == 30)*final_faces_df[i+j, 'face']
  final_faces_df[i+j+1, 'intensity30'] <- (faces_df[i, 'intensity'] == 30)*final_faces_df[i+j+1, 'face']
  final_faces_df[i+j+2, 'intensity30'] <- (faces_df[i, 'intensity'] == 30)*final_faces_df[i+j+2, 'face']
  # intensity40 ^
  final_faces_df[i+j, 'intensity40'] <- (faces_df[i, 'intensity'] == 40)*final_faces_df[i+j, 'face']
  final_faces_df[i+j+1, 'intensity40'] <- (faces_df[i, 'intensity'] == 40)*final_faces_df[i+j+1, 'face']
  final_faces_df[i+j+2, 'intensity40'] <- (faces_df[i, 'intensity'] == 40)*final_faces_df[i+j+2, 'face']
  # intensity50 ^
  final_faces_df[i+j, 'intensity50'] <- (faces_df[i, 'intensity'] == 50)*final_faces_df[i+j, 'face']
  final_faces_df[i+j+1, 'intensity50'] <- (faces_df[i, 'intensity'] == 50)*final_faces_df[i+j+1, 'face']
  final_faces_df[i+j+2, 'intensity50'] <- (faces_df[i, 'intensity'] == 50)*final_faces_df[i+j+2, 'face']
  # correct - (1) they correctly identified the gender of the face (0) they did not, or it wasn't a face
  # NOTE: This is different from the definition in E-Prime output
  if (faces_df[i, 'gender'] == 1) {
    final_faces_df[i+j, 'correct'] <- (!is.na(faces_df[i, 'ImageDisplay2']) & faces_df[i, 'ImageDisplay2'] == 4)*final_faces_df[i+j, 'face']
  } else {

  }
  j=j+2
}
