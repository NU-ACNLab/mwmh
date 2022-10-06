### This script turns eprime task response and task design information into
### a tsv compliant with BIDS
###
### Ellyn Butler
### March 29, 2022 - July 27, 2022


# TO DO: Turn these into command line arguments for job submission
args = commandArgs(trailingOnly=TRUE)
sub = args[1] # e.g., MWMH001
ses = args[2] # e.g., 1

base_path <- '/projects/b1108/studies/mwmh/data/processed/neuroimaging/behavioral/'

bids_path <- '/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/sub-'

#################################### Avoid ####################################

avoid_df <- read.csv(paste0(base_path, 'avoid_2022-07-28.csv'))
avoid_df <- avoid_df[avoid_df$subid %in% sub & avoid_df$sesid %in% ses, ]

if (nrow(avoid_df) > 10) {
  row.names(avoid_df) <- 1:nrow(avoid_df)

  fix2_dur <- c(avoid_df[2:nrow(avoid_df), 'Stm.OnsetTime'] - (avoid_df[1:(nrow(avoid_df) - 1),
    'Stm.OnsetToOnsetTime'] + avoid_df[1:(nrow(avoid_df) - 1), 'Fixation.OnsetTime'] +
    avoid_df[1:(nrow(avoid_df) - 1), 'Fixation.OnsetToOnsetTime']),
    avoid_df[nrow(avoid_df), 'Jit2'])

  eprime_to_pulse <- avoid_df[1, 'Stm.OnsetTime'] - 12000

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

  final_avoid_df <- data.frame(onset=NA, duration=NA, trial=NA, cue=NA, fix1=NA,
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
    ######## NOTE (October 5, 2022): Amount column incorrectly displays an amount
    ######## even when the subject chose to risk no money (and no 0s), therefore
    ######## `press*` was added to each of the lines of code utilizing this column
    ######## for which they risked money, and `press*` was added to each of the
    ######## lines of code utilizing this column for which they did not risk money.
    ######## Confusingly, the 'Feedbk' and 'Message' columns disagree on what the
    ######## subject saw. One can only hope that they saw the 'Message' column
    ######## values, considering those are the correct ones.
    # reward - feedback & reward ($ > 0)
    final_avoid_df[i+j, 'reward'] <- press*(avoid_df[i, 'Amount'] > 0)*final_avoid_df[i+j, 'feedback']
    final_avoid_df[i+j+1, 'reward'] <- press*(avoid_df[i, 'Amount'] > 0)*final_avoid_df[i+j+1, 'feedback']
    final_avoid_df[i+j+2, 'reward'] <- press*(avoid_df[i, 'Amount'] > 0)*final_avoid_df[i+j+2, 'feedback']
    final_avoid_df[i+j+3, 'reward'] <- press*(avoid_df[i, 'Amount'] > 0)*final_avoid_df[i+j+3, 'feedback']
    # loss - feedback & loss ($ < 0)
    final_avoid_df[i+j, 'loss'] <- press*(avoid_df[i, 'Amount'] < 0)*final_avoid_df[i+j, 'feedback']
    final_avoid_df[i+j+1, 'loss'] <- press*(avoid_df[i, 'Amount'] < 0)*final_avoid_df[i+j+1, 'feedback']
    final_avoid_df[i+j+2, 'loss'] <- press*(avoid_df[i, 'Amount'] < 0)*final_avoid_df[i+j+2, 'feedback']
    final_avoid_df[i+j+3, 'loss'] <- press*(avoid_df[i, 'Amount'] < 0)*final_avoid_df[i+j+3, 'feedback']
    # nothing - feedback & $0
    final_avoid_df[i+j, 'nothing'] <- (1-press)*final_avoid_df[i+j, 'feedback']
    final_avoid_df[i+j+1, 'nothing'] <- (1-press)*final_avoid_df[i+j+1, 'feedback']
    final_avoid_df[i+j+2, 'nothing'] <- (1-press)*final_avoid_df[i+j+2, 'feedback']
    final_avoid_df[i+j+3, 'nothing'] <- (1-press)*final_avoid_df[i+j+3, 'feedback']
    # gain 50
    final_avoid_df[i+j, 'gain50'] <- press*(avoid_df[i, 'Amount'] == 50)*final_avoid_df[i+j, 'feedback']
    final_avoid_df[i+j+1, 'gain50'] <- press*(avoid_df[i, 'Amount'] == 50)*final_avoid_df[i+j+1, 'feedback']
    final_avoid_df[i+j+2, 'gain50'] <- press*(avoid_df[i, 'Amount'] == 50)*final_avoid_df[i+j+2, 'feedback']
    final_avoid_df[i+j+3, 'gain50'] <- press*(avoid_df[i, 'Amount'] == 50)*final_avoid_df[i+j+3, 'feedback']
    # gain 10
    final_avoid_df[i+j, 'gain10'] <- press*(avoid_df[i, 'Amount'] == 10)*final_avoid_df[i+j, 'feedback']
    final_avoid_df[i+j+1, 'gain10'] <- press*(avoid_df[i, 'Amount'] == 10)*final_avoid_df[i+j+1, 'feedback']
    final_avoid_df[i+j+2, 'gain10'] <- press*(avoid_df[i, 'Amount'] == 10)*final_avoid_df[i+j+2, 'feedback']
    final_avoid_df[i+j+3, 'gain10'] <- press*(avoid_df[i, 'Amount'] == 10)*final_avoid_df[i+j+3, 'feedback']
    # lose 10
    final_avoid_df[i+j, 'lose10'] <- press*(avoid_df[i, 'Amount'] == -10)*final_avoid_df[i+j, 'feedback']
    final_avoid_df[i+j+1, 'lose10'] <- press*(avoid_df[i, 'Amount'] == -10)*final_avoid_df[i+j+1, 'feedback']
    final_avoid_df[i+j+2, 'lose10'] <- press*(avoid_df[i, 'Amount'] == -10)*final_avoid_df[i+j+2, 'feedback']
    final_avoid_df[i+j+3, 'lose10'] <- press*(avoid_df[i, 'Amount'] == -10)*final_avoid_df[i+j+3, 'feedback']
    # lose 50
    final_avoid_df[i+j, 'lose50'] <- press*(avoid_df[i, 'Amount'] == -50)*final_avoid_df[i+j, 'feedback']
    final_avoid_df[i+j+1, 'lose50'] <- press*(avoid_df[i, 'Amount'] == -50)*final_avoid_df[i+j+1, 'feedback']
    final_avoid_df[i+j+2, 'lose50'] <- press*(avoid_df[i, 'Amount'] == -50)*final_avoid_df[i+j+2, 'feedback']
    final_avoid_df[i+j+3, 'lose50'] <- press*(avoid_df[i, 'Amount'] == -50)*final_avoid_df[i+j+3, 'feedback']
    j=j+3
  }

  # SANITY CHECK: Does the onset time of the i+1 row equal the onset + duration of i?
  sanity <- final_avoid_df[2:nrow(final_avoid_df), 'onset'] - (final_avoid_df[1:(nrow(final_avoid_df) - 1),'onset'] + final_avoid_df[1:(nrow(final_avoid_df) - 1), 'duration']) < .00001

  if (FALSE %in% sanity) {
    stop('The onsets and durations are not matching up')
  }

  # Use the required NA value (n/a)
  final_avoid_df[is.na(final_avoid_df)] <- 'n/a'

  # Write out tsv to bids directory
  write.table(final_avoid_df, paste0(bids_path, sub, '/ses-', ses, '/func/sub-',
    sub, '_ses-', ses, '_task-avoid_events.tsv'), row.names=FALSE, sep='\t', quote=FALSE)

  # final_avoid_df should have 96*4 = 384 rows
}


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

faces_df <- read.csv(paste0(base_path, 'faces_2022-07-28.csv'))
faces_df <- faces_df[faces_df$subid %in% sub & faces_df$sesid %in% ses, ]

if (nrow(faces_df) > 10) {
  if (is.na(faces_df[1, 'gender'])) {
    faces_df <- faces_df[2:nrow(faces_df), ] # NOT SURE IF APPROPRIATE, but first and last rows have mostly NAs
  }
  if (is.na(faces_df[nrow(faces_df), 'gender'])) {
    faces_df <- faces_df[1:(nrow(faces_df)-1), ]
  }

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

  #onset,duration,trial,face,blank,fix,female,happy,intensity10,intensity20,intensity30,intensity40,intensity50,correct,press

  final_faces_df <- data.frame(onset=NA, duration=NA, trial=NA, face=NA, blank=NA,
                          fix=NA, female=NA, happy=NA, intensity10=NA,
                          intensity20=NA, intensity30=NA, intensity40=NA,
                          intensity50=NA, correct=NA, press=NA)

  if (sum(!is.na(faces_df$ImageDisplay2.RESP)) > 1) {
    corr_gender_resp <- cor(faces_df$ImageDisplay2.RESP, faces_df$gender, use='complete.obs')
  } else {
    corr_gender_resp <- 0
  }

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
    # April 14, 2022: THIS IS APPROXIMATE. There were issues with the button boxes. see evaluate_eprime.R for details
    # NOTE: This is different from the definition in E-Prime output
    if (!is.na(faces_df[i, 'ImageDisplay2.RESP'])) {
      final_faces_df[(i+j):(i+j+2), 'press'] <- c(1, 0, 0)
      if (1 %in% faces_df$ImageDisplay2) {
        # If corr positive (preponderance of the evidence that it should be)
        if (corr_gender_resp > 0) {
          if (faces_df[i, 'gender'] == 1) {
            final_faces_df[i+j, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 1)*final_faces_df[i+j, 'face']
            final_faces_df[i+j+1, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 1)*final_faces_df[i+j+1, 'face']
            final_faces_df[i+j+2, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 1)*final_faces_df[i+j+2, 'face']
          } else {
            final_faces_df[i+j, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 2)*final_faces_df[i+j, 'face']
            final_faces_df[i+j+1, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 2)*final_faces_df[i+j+1, 'face']
            final_faces_df[i+j+2, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 2)*final_faces_df[i+j+2, 'face']
          }
        # If corr negative
        } else {
          if (faces_df[i, 'gender'] == 1) {
            final_faces_df[i+j, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 2)*final_faces_df[i+j, 'face']
            final_faces_df[i+j+1, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 2)*final_faces_df[i+j+1, 'face']
            final_faces_df[i+j+2, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 2)*final_faces_df[i+j+2, 'face']
          } else {
            final_faces_df[i+j, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 1)*final_faces_df[i+j, 'face']
            final_faces_df[i+j+1, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 1)*final_faces_df[i+j+1, 'face']
            final_faces_df[i+j+2, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 1)*final_faces_df[i+j+2, 'face']
          }
        }
      } else if (4 %in% faces_df$ImageDisplay2.RESP) {
        # If corr positive
        if (corr_gender_resp > 0) {
          if (faces_df[i, 'gender'] == 1) {
            final_faces_df[i+j, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 3)*final_faces_df[i+j, 'face']
            final_faces_df[i+j+1, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 3)*final_faces_df[i+j+1, 'face']
            final_faces_df[i+j+2, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 3)*final_faces_df[i+j+2, 'face']
          } else {
            final_faces_df[i+j, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 4)*final_faces_df[i+j, 'face']
            final_faces_df[i+j+1, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 4)*final_faces_df[i+j+1, 'face']
            final_faces_df[i+j+2, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 4)*final_faces_df[i+j+2, 'face']
          }
        # If corr negative (what it is most often in the 3s and 4s case)
        } else {
          if (faces_df[i, 'gender'] == 1) {
            final_faces_df[i+j, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 4)*final_faces_df[i+j, 'face']
            final_faces_df[i+j+1, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 4)*final_faces_df[i+j+1, 'face']
            final_faces_df[i+j+2, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 4)*final_faces_df[i+j+2, 'face']
          } else {
            final_faces_df[i+j, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 3)*final_faces_df[i+j, 'face']
            final_faces_df[i+j+1, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 3)*final_faces_df[i+j+1, 'face']
            final_faces_df[i+j+2, 'correct'] <- (faces_df[i, 'ImageDisplay2.RESP'] == 3)*final_faces_df[i+j+2, 'face']
          }
        }
      }
    } else {
      final_faces_df[(i+j):(i+j+2), 'correct'] <- 0
      final_faces_df[(i+j):(i+j+2), 'press'] <- 0
    }
    j=j+2
  }



  # SANITY CHECK: Does the onset time of the i+1 row equal the onset + duration of i?
  sanity <- final_faces_df[2:nrow(final_faces_df), 'onset'] - (final_faces_df[1:(nrow(final_faces_df) - 1), 'onset'] + final_faces_df[1:(nrow(final_faces_df) - 1), 'duration']) < .00001

  if (FALSE %in% sanity) {
    stop('The onsets and durations are not matching up')
  }

  # Use the required NA value (n/a)
  final_faces_df[is.na(final_faces_df)] <- 'n/a'

  # Write out tsv to bids directory
  write.table(final_faces_df, paste0(bids_path, sub, '/ses-', ses, '/func/sub-',
    sub, '_ses-', ses, '_task-faces_events.tsv'), row.names=FALSE, sep='\t', quote=FALSE)
}
