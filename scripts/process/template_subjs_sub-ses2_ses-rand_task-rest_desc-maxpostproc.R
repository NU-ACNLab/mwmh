### This script selects randomly either the first or
### second session for template construction, among
### those subjects that have both sessions, and selects
### only the second session for the subjects that just
### have the second session available
### 
### Ellyn Butler
### October 6, 2024

d <- read.csv('/projects/b1108/projects/violence_sex_development/data/combined_data_2024-09-23.csv')

dall <- d
d <- d[!is.na(d$exp_b_pos) & !is.na(d$FC_b_pos) & !is.na(d$RCADS_sum) & !is.na(d$num_pastyear), ]
d1 <- d[d$sesid == 1, ]
d2 <- d[d$sesid == 2, ]

subids <- d2$subid

temp_ids <- data.frame(subid = subids, sesid = NA)
sesid1 = 0
sesid2 = 0
for (subid in subids) {
    if (subid %in% d1$subid & sesid1 < 110 & sesid2 < 110) {
        sesid <- sample(1:2, 1)
        if (sesid == 1) {
            sesid1 = sesid1 + 1
        } else {
            sesid2 = sesid2 + 1
        } 
    } else if (sesid1 == 110 | !(subid %in% d1$subids)) {
        sesid = 2
        sesid2 = sesid2 + 1
    } else if (sesid2 == 110) {
        sesid = 1
        sesid1 = sesid1 + 1
    }
    temp_ids[temp_ids$subid == subid, 'sesid'] = sesid
}

write.csv(temp_ids, '/projects/b1108/studies/mwmh/data/processed/neuroimaging/tabulated/temp_subjs_sub-ses2_ses-rand_task-rest_desc-maxpostproc.csv', row.names = FALSE)