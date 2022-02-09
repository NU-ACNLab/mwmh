### This script helps to determine which sessions are "extra" (e.g., an initial
### attempt of a scanning session that was later repeated)
###
### Ellyn Butler
### February 2, 2022


hdr_df <- read.csv('/projects/b1108/studies/mwmh/data/raw/neuroimaging/meta/params_2022-02-02.csv')

hdr_df$subid_sesid <- paste(hdr_df$subid, hdr_df$sesid, sep='_')

mprage_df <- hdr_df[!is.na(hdr_df$SliceThickness) & round(hdr_df$SliceThickness, digits=1) == .8, ]
# In dicom header: ACQ Slice Thickness//0.79999995231628

# Does every session have an mprage? Yes
length(unique(mprage_df$subid_sesid)) == length(unique(hdr_df$subid_sesid))

# Are there duplicate sessions? Yes, tons
nrow(mprage_df) == nrow(mprage_df[!duplicated(mprage_df$subid_sesid), ])

# Duplicates (433 sessions have 2 t1w images, 3 have 3, and 13 have 4)
table(table(mprage_df$subid_sesid))

# Check out the first case
mprage_df[mprage_df$subid_sesid == 'MWMH219_2', ]
hdr_df[hdr_df$subid_sesid == 'MWMH219_2', ]
