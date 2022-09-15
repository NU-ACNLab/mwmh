### This script plots age over time so that I can begin to get a sense of the
### period of adolescence in which I could do longitudinal analyses
###
### Ellyn Butler
### September 15, 2022

library(ggplot2)
library(dplyr)

age_df <- read.csv('/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/demographic/age_visits_2022-07-26.csv')
viol_df <- read.csv('/Users/flutist4129/Documents/Northwestern/projects/violence_mediation/data/violence.csv')

age_df <- age_df[!is.na(age_df$age_mri), ]
viol_df <- viol_df[!is.na(viol_df$ever), ]

final_df <- merge(age_df, viol_df)
final_df$subid_sesid <- paste(final_df$subid, final_df$sesid, sep="_")
row.names(final_df) <- 1:nrow(final_df)
checkalone <- table(final_df$subid)[table(final_df$subid) == 1]
final_df <- final_df[!(final_df$subid %in% names(checkalone)),]
row.names(final_df) <- 1:nrow(final_df)

first_df <- final_df[final_df$sesid == 1, ]
first_df$ever_first <- first_df$ever
second_df <- final_df[final_df$sesid == 2, ]

sortedids <- final_df %>% group_by(subid) %>% summarise(m=min(age_mri)) %>% arrange(m)
sortedids$row <- as.numeric(rownames(sortedids))
sorted_df <- final_df %>% left_join(sortedids %>% select(subid, row), by='subid')
sorted_df <- merge(sorted_df, first_df[, c('subid', 'ever_first')], by='subid')
sorted_df$Violence <- ordered(sorted_df$ever_first, c(1, 0))


viol_subtit <- paste0("N Yes=", nrow(first_df[first_df$ever == 1,]),
  ", N No=", nrow(first_df[first_df$ever == 0,]))
viol_fig <- ggplot(data = sorted_df, aes(x=reorder(row, age_mri, FUN = min),
    y=age_mri, color=Violence)) + theme_linedraw() +
  geom_point(size = .5, alpha = .5) + geom_line(alpha = .5) +
  scale_x_discrete(breaks = seq(1, length(sortedids$subid), 50)) +
  coord_flip(clip = "off") +
  scale_color_manual(values = c("aquamarine3", "darkred"), labels=c("Yes", "No"))+
  labs(title = "Baseline Violence Exposure", subtitle = viol_subtit,
    y = "Age (years)", x = "Participant") +
  theme(legend.position = c(.8,.2))

pdf('/Users/flutist4129/Documents/Northwestern/studies/mwmh/plots/age_trajectories_violence.pdf')
viol_fig
dev.off()
