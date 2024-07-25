### This script checks that the curate conditions in manually_curate.py do not
### pick up on any unwanted scans
###
### Ellyn Butler
### April 21, 2022 (additional notes October 5, 2022)


library('data.table')

df <- read.csv('/projects/b1108/studies/mwmh/data/raw/neuroimaging/meta/params_2022-10-06.csv')

# October 6, 2022: ^ This file is short 44 sessions... investigating
bids_df <- read.csv('/projects/b1108/studies/mwmh/data/raw/neuroimaging/meta/bids_10-06-2022.csv')
params_ids <- unique(paste0(df$subid, df$sesid))
bids_ids <- unique(bids_df$subid_sesid)
bids_ids[!(bids_ids %in% params_ids)]

# How many sessions are in here? 492
length(unique(paste0(df$subid, df$sesid)))


##################################### T1w #####################################

t1w_df <- df[grepl('tfl_epinav_ME2', df$ProtocolName) & df$NDicoms == 208,
  c('RepetitionTime', 'SequenceName', 'SliceThickness')]
dim(t1w_df) # Should be 492...
dim(df[df$NDicoms == 208,]) # 509... Loosen ProtocolName restriction?

t1w_df2 <- df[df$NDicoms == 208, c('ProtocolName', 'RepetitionTime', 'SequenceName', 'SliceThickness')]
# A lot of them have "tffl" instead of "tfl"
unique(t1w_df2$ProtocolName) # four unique ones
table(t1w_df2$ProtocolName)

# 416 dicoms? Two separate echos

# Final conditions (+ Python: dcm.AcquisitionMatrix[1] == 320... which was true of all of them)
t1w_df2 <- df[(grepl('l_epinav_ME2', df$ProtocolName) | grepl('MPRAGE_SAG_0.8iso', df$ProtocolName)) & df$NDicoms == 208,]
dim(t1w_df2)
# 509... a few subjects had their t1w image redone in a session
# NOTE: Don't be freaked out that the echo times appear to be different across
# scans. Each scan had two echoes, and the scan number that was chosen was the
# scan that contained both of them (each standard subject has three t1w dicom
# directories). The reason different echo times show up is because the
# representative dicom header that was using to generate the master csv only
# contained one of the two echo times.

##################################### DTI #####################################

dti_df <- df[grepl('DTI_MB4_68dir_1pt5mm_b1k', df$ProtocolName) & df$NDicoms > 60 &
  df$SliceThickness == 1.5 & df$RepetitionTime == 2500,]
dim(dti_df) # 2417 sessions... whoops. Need to be more exclusionary

dti_df2 <- df[grepl('DTI_MB4_68dir_1pt5mm_b1k', df$ProtocolName) & df$NDicoms > 60 &
  df$SliceThickness == 1.5 & df$RepetitionTime == 2500 & df$NDicoms < 70,]
dim(dti_df2) # 492. Yes.

dti_df2$subid_sesid <- paste0(dti_df2$subid, dti_df2$sesid)
length(unique(dti_df2$subid_sesid)) #491


#################################### FACES ####################################

faces_df <- df[(grepl('FACES', df$ProtocolName) | grepl('MB2_task', df$ProtocolName)) &
  df$NDicoms < 205 & df$NDicoms > 195 & df$SliceThickness < 1.8,]
dim(faces_df) # 466
table(faces_df$ProtocolName)

faces_df$subid_sesid <- paste0(faces_df$subid, faces_df$sesid)
length(faces_df$subid_sesid) == length(unique(faces_df$subid_sesid))
# ^ no session has more than one faces task with these criteria

# Check out the wonky protocol name
faces_df[faces_df$ProtocolName == 'MB2_task_20_70_2000_1pt7iso', ]
subs_mb2 <- faces_df[faces_df$ProtocolName == 'MB2_task_20_70_2000_1pt7iso', 'subid']
df[df$subid == subs_mb2[1], ]
df[df$subid == subs_mb2[2], ]
df[df$subid == subs_mb2[3], ]

# What if we split up 'FACES' and 'MB2_task'?
faces_prot_df <- df[which(grepl('FACES', df$ProtocolName) & df$SliceThickness < 1.8),]
mb2_prot_df <- df[which(grepl('MB2_task', df$ProtocolName) & df$NDicoms < 205 & df$NDicoms > 195 &
  df$SliceThickness < 1.8),]

faces_both_prot_df <- rbind(faces_prot_df, mb2_prot_df)
faces_both_prot_df$subid_sesid <- paste0(faces_both_prot_df$subid, faces_both_prot_df$sesid)
length(unique(faces_both_prot_df$subid_sesid))

faces_both_prot_df[which(!(faces_both_prot_df$subid_sesid %in% unique(faces_df$subid_sesid))), ]


#################################### AVOID ####################################

avoid_df <- df[(grepl('PASSIVE', df$ProtocolName) | grepl('MB2_task', df$ProtocolName)) &
  df$NDicoms < 305 & df$NDicoms > 295 & df$SliceThickness < 1.8,]
dim(avoid_df) # 473
table(avoid_df$ProtocolName)

avoid_df$subid_sesid <- paste0(avoid_df$subid, avoid_df$sesid)
length(avoid_df$subid_sesid) == length(unique(avoid_df$subid_sesid))

# Check out the wonky protocol name
avoid_df[avoid_df$ProtocolName == 'MB2_task_20_70_2000_1pt7iso', ]
subs_mb2 <- avoid_df[avoid_df$ProtocolName == 'MB2_task_20_70_2000_1pt7iso', 'subid']
df[df$subid == subs_mb2[1], ]
df[df$subid == subs_mb2[2], ]
df[df$subid == subs_mb2[3], ]
df[df$subid == subs_mb2[4], ]

# What if we split up 'PASSIVE' and 'MB2_task'?
avoid_prot_df <- df[which(grepl('PASSIVE', df$ProtocolName) & df$SliceThickness < 1.8),]
mb2_prot_df <- df[which(grepl('MB2_task', df$ProtocolName) & df$NDicoms < 305 & df$NDicoms > 295 &
  df$SliceThickness < 1.8),]

avoid_both_prot_df <- rbind(avoid_prot_df, mb2_prot_df)
avoid_both_prot_df$subid_sesid <- paste0(avoid_both_prot_df$subid, avoid_both_prot_df$sesid)
length(unique(avoid_both_prot_df$subid_sesid))

avoid_both_prot_df[which(!(avoid_both_prot_df$subid_sesid %in% unique(avoid_df$subid_sesid))), ]

##################################### REST #####################################

rest_df <- df[grepl('Mb8_rest_HCP', df$ProtocolName) & df$SliceThickness %in% 2,]
dim(rest_df) # 437





# TO DO:
# 1.) Check out task confusion with behavioral files. If behavioral files have
#     sequence number, should be able to figure out what this crap is.
#     Still a problem? Doesn't look like it.
boo <- df[df$ProtocolName == 'MB2_task_20_70_2000_1pt7iso', ]
df[grepl('MB2_task', df$ProtocolName), ]


#
