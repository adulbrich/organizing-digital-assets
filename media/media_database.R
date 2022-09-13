# install.packages(c("exifr", "data.table", "stringr", "jsonlite", "lubridate", "OpenImageR"))
library(stringr)
library(data.table)
library(exifr)
library(lubridate)
library(jsonlite)
library(OpenImageR)

source("./media/functions.R")

library_path <- c("//alexandria/home/Pictures/Originals")

# List all_files
all_files <- get_files(library_path)
# saveRDS(
#   all_files,
#   file = str_c(
#     library_path
#     , "/"
#     , today()
#     , "-all-media-files-no-exif.rds"
#   )
# )

# TODO: do not calculate EXIF if already present

# Get Exif data
all_exif <- get_exif(all_files)
# saveRDS(
#   all_exif,
#   file = str_c(
#     library_path
#     , "/"
#     , today()
#     , "-all-media-files-exif-only.rds"
#   )
# )

all_files <- merge(all_files, all_exif, by = "SourceFile", all.x = T)

# Check existing filenames
check_filename_format(all_files)
View(all_files[filename_check == 0, ])

# Extract Dates
extract_dates(all_files)
View(all_files[is.na(date), ])

# Add Missing Information
add_missing_camera_information(all_files)

# Statistics
all_files[, .N, by = c("fileExtension", "FileTypeExtension")]
all_files[, .N, by = c("Model")]
all_files[is.na(date_time_original), .N]
all_files[, .N, by = c("Model", "FileTypeExtension")]

# Split all_files that have no date
# all_files_no_date <- all_files[is.na(date), ]
# all_files <- all_files[!is.na(date), ]

# New File Name
new_file_name(all_files)

# Check and Correct Duplicates
check_duplicates(all_files)
all_files[dupbis == TRUE, .N]

all_files_duplicates <- all_files[dupbis == TRUE, ]
all_files <- all_files[dupbis == FALSE, ]

all_files <- all_files[!str_detect(path, "1986--P2Y"), ]

# compare current with new names
all_files[, filename_check := (str_c(fileName,".",fileExtension)==filename_formatted)]
View(all_files[filename_check ==  FALSE, ])
