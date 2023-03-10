# gets content from pdf, extracts and cleans data, and saves output to csv files
# plots data (deactivated)
# gets Occupancy rates in Montreal emergency rooms from pdf (backup)

# packages:
library(stringr)
library(dplyr)
# library(ggplot2)
library(tidyr)
library(pdftools)

url <- "https://www.msss.gouv.qc.ca/professionnels/statistiques/documents/urgences/Rap_Quotid_SituatUrgence1.pdf"

# read pdf
text_pdf <- pdf_text(url) 

# read page 7 of pdf file (montreal)
text_pdf <- text_pdf[[7]] 

# get rows from pdf
by_row_pdf <- str_split(text_pdf, pattern = "\n")

# get last update and time
update <- by_row_pdf[[1]][4]
update1 <- by_row_pdf[[1]][53]

# OBS! last line contains number! replace number in row 42: 
by_row_pdf[[1]][42] <- str_replace(by_row_pdf[[1]][42], "\\(06\\) ", "")

# extract line by line 14:42
rows <- by_row_pdf[[1]][14:42]
df <- data.frame(matrix(ncol = 45, nrow = 0)) # create empty data frame with 45 columns 
row_counter = 1 # row counter = needed for writing rows to data frame 
for (j in 1:length(rows)) {
  x <- rows[j]
  # if line start with m/M or d/D: name = ""
  if (str_detect(x, "^m") || str_detect(x, "^M")  || str_detect(x, "^d") || str_detect(x, "^D")) { 
    name = "" 
    # else if line shorter than 50 characters: name = x
  } else if (nchar(x) < 50) {
    name <- x
    # else start string processing (= getting name and numbers)
  } else {
    y <- str_extract_all(x, boundary("word"))[[1]] # separate strings into single word elements
    for (i in 1:length(y)){ # concatenate list elements to one string
      name <- paste(name, y[i])
      # print(name)
    }
    name <- name
    name <- str_trim(name, side = "left") # remove white space on left side
    nice_string <- str_replace_all(name, "N D", "99999") # replace missings "N D" with 99999
    # split at first whitespace \\s followed by "(?=" number [0-9]: 
    name <- str_split(nice_string, "\\s(?=[0-9])", 2)[[1]][1] # get hospital name
    numbers <- str_split(nice_string, "\\s(?=[0-9])", 2)[[1]][2] # get numbers
    numbers <- str_replace_all(numbers, "99999", "NA") # replace 9999 with NA
    numbers <- str_replace_all(numbers, " ", ",") # replace whitespace with comma
    # write row with name and 44 numbers to data frame
    df[row_counter,] <- data.frame(name, str_split_fixed(numbers, pattern = ",", 44)) 
    # set variables for next loop
    row_counter <- row_counter + 1
    name = ""
  }
}

# rename hospital names
df$X1[1] <- "Institut universitaire de sant?? mentale de Montr??al"
df$X1[5] <- "H??pital du Sacr??-Coeur de Montr??al"
df$X1[8] <- "Centre hospitalier de l'universit?? de Montr??al"
df$X1[13] <- "H??pital g??n??ral juif Sir Mortimer B. Davis"

# write data to csv files

###################################
# write complete table to csv 
write.csv(df, file = "data/table_all.csv", row.names = FALSE)

###################################
# write last 7 days to csv
df_7days <- data.frame(matrix(ncol = 22, nrow = 0))
days <- 0
for (k in 1:7) {
  row <- df %>% select(hospital_name = X1, occupancy_rate = paste0("X",39+days)) %>%
    pivot_wider(names_from=hospital_name, values_from=occupancy_rate)
  df_7days[k,] <- data.frame(as.character(Sys.Date()-6+days), row)
  # print(row)
  days = days + 1
}
names(df_7days) <- names(c("Date",row)) # replace column names, "Date" doesn't show?
names(df_7days)[1] <- "Date"
write.csv(df_7days, file = "data/last7days.csv", row.names = FALSE)

###################################
# write only today's occupation rate (column 45) to file
daily <- df %>% select(hospital_name = X1, occupancy_rate = X45) %>%
  mutate(Date = as.character(Sys.Date())) %>%
  pivot_wider(names_from=hospital_name, values_from=occupancy_rate)
# write.csv(daily, file = "data/daily_data.csv", row.names = FALSE)
write.table(daily, "data/daily_data.csv", append = T, row.names = F, col.names = F, sep = ",")

###################################
## plot last 7 days
# df_7days %>%
# select(Date, total = "Total Montr??al") %>%
# mutate(total = as.numeric(total)) %>%
## plot data
#  ggplot(aes(y=total, x=Date, fill=total)) + 
#  geom_col(position = "identity", size = 0.5, show.legend = F) +
#  geom_text(aes(label = paste0(total,"%")), vjust = 1.5, colour = "white", size = 3.5) +
#  theme_minimal() + 
#  scale_fill_gradient2(low = "light green", high = "red", mid = "yellow", midpoint = 80) +
#  theme(axis.text.x = element_text(angle = 90), 
#    panel.grid.major.x = element_blank(), # remove vertical grid lines
#    panel.grid.major.y = element_line()) + # set horizontal lines only
#  labs(caption = paste("\nlast update:", update), x = NULL, y = NULL) 

## save output
# ggsave("img/last7days.png", width = 4, height = 4)
