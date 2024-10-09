### This script selects randomly either the first or
### second session for template construction, among
### those subjects that have both sessions, and selects
### only the second session for the subjects that just
### have the second session available
### 
### Ellyn Butler
### October 6, 2024

set.seed(2000)

d <- read.csv('/projects/b1108/projects/violence_sex_development/data/combined_data_2024-09-23.csv')

d <- d[!is.na(d$exp_b_pos) & !is.na(d$FC_b_pos), ]
d1 <- d[d$sesid == 1, ]
d2 <- d[d$sesid == 2, ]

subids <- d2$subid

temp_ids <- data.frame(subid = subids, sesid = NA)

subids_onlyses2 <- subids[!(subids %in% d1$subid)]

temp_ids[temp_ids$subid %in% subids_onlyses2, 'sesid'] <- 2

sesid1 = 0
sesid2 = length(subids_onlyses2)
for (subid in subids) {
    if (is.na(temp_ids[temp_ids$subid == subid, 'sesid'])) {
        # If we have reached the max for data from ses-1 or the subid
        # does not have ses-1
        if (sesid1 == 110) {
            sesid = 2
            sesid2 = sesid2 + 1
        # If the subid has ses-1 and we haven't reached the max for
        # either data from ses-1 or ses-2
        } else if (subid %in% d1$subid & sesid1 < 110 & sesid2 < 110) {
            sesid <- sample(1:2, 1)
            if (sesid == 1) {
                sesid1 = sesid1 + 1
            } else {
                sesid2 = sesid2 + 1
            } 
        # If we have reached the max for data from ses-2
        } else if (sesid2 == 110) {
            sesid = 1
            sesid1 = sesid1 + 1
        }
        temp_ids[temp_ids$subid == subid, 'sesid'] = sesid
    }
}

write.csv(temp_ids, '/projects/b1108/studies/mwmh/data/processed/neuroimaging/tabulated/temp_subjs_sub-ses2_ses-rand_task-rest_desc-maxpostproc.csv', row.names = FALSE)