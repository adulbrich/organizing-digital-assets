# install.packages(c("exifr", "data.table", "stringr", "jsonlite", "lubridate"))
library(stringr)
library(data.table)
library(exifr)
library(lubridate)
library(jsonlite)

source("./media/functions.R")

path <- "P:/Takeout/Google Photos"
library_path <- c("//alexandria/home/Pictures/Originals")

# List files
files <- get_files(path)
saveRDS(file, "P:/files-no-exif.RDS")

# Get Exif data
exif <- get_exif(files)
saveRDS(exif, "P:/files-exif-only.RDS")
files <- merge(files, exif, by = "SourceFile", all.x = T)

# Extract Dates
extract_dates(files)

# Add Missing Information
add_missing_camera_information(files)

# Statistics
files[, .N, by = c("fileExtension", "FileTypeExtension")]
files[, .N, by = c("Model")]
files[is.na(date_time_original), .N]
files[, .N, by = c("Model", "FileTypeExtension")]

# Split files that have no date
files_no_date <- files[is.na(date), ]
files <- files[!is.na(date), ]

# reset
# files[, c("filename_formatted_v1", "filename_formatted_v2", "duplicate_first_pass", "duplicate_second_pass", "dup", "dupbis", "file_exists_1", "file_exists_2") := NULL]

# Separate WhatsApp Files
files_whatsapp <- files[str_detect(fileName, "-WA"), ]
files <- files[!str_detect(fileName, "-WA"), ]

# move and remove WhatsApp files
# files_whatsapp[, targetFile := str_replace(str_c("P:/Takeout-WhatsApp/",str_to_upper(fileName)),"JPEG", "JPG")]
# file.copy(from = files_whatsapp[, SourceFile], to = files_whatsapp[, targetFile])
# file.remove(files_whatsapp[, SourceFile])

# New File Name
new_file_name(files, version = "all")

# Check and Correct Duplicates
check_duplicates(files, version = "all")

# Remove true duplicates
files_true_duplicates <- files[duplicate_second_pass == TRUE,]
files <- files[duplicate_second_pass == FALSE,]

# Import Main Database
all_files <- readRDS("//alexandria/home/Pictures/Originals/2022-09-09-all-media-files.rds")
all_files[, .N, by = c("fileExtension", "FileTypeExtension")]


# Check if file already exist in main database
all_files[, index1 := str_to_upper(str_c(date_time_original, "--", Model, ".", FileTypeExtension))]
all_files[, index1 := str_replace(index1, "JPEG", "JPG")]
files[, index1 := str_to_upper(str_c(date_time_original, "--", Model, ".", FileTypeExtension))]
files <- merge(
  files,
  all_files[!is.na(filename_formatted_v1), .(index1, file_exists_1 = 1)],
  by = c("index1"),
  all.x = TRUE
)
files[, .N, by = "file_exists_1"]
View(files[is.na(file_exists_1)])

# Check if file already exist in main database
all_files[, index2 := date]
files[, index2 := date]
files <- merge(
  files,
  unique(all_files[!is.na(filename_formatted_v1), .(index2, file_exists_2 = 1)]),
  by = c("index2"),
  all.x = TRUE
)
files[, .N, by = c("file_exists_1", "file_exists_2")]
View(files[is.na(file_exists_2)])

# Remove existing files
files_exist <- files[file_exists == 1, ]
files_new <- files[is.na(file_exists), ]

# Hash Images
files[fileExtension %in% c("JPG", "JPEG", "PNG", "TIFF", "TIF"), dhash := image_dhash(str_to_lower(SourceFile)), by = SourceFile]

# Directories
directories <- build_directory_index(library_path)
assign_directory(files, directories, library_path)

temp <- unique(files[, .(directory)])
temp[, dir_exists := dir.exists(directory)]
files <- merge(
  files,
  temp,
  by = "directory",
  all.x = TRUE
)
files[, .N, by = c("file_exists_1", "file_exists_2", "dir_exists")]

View(files[file_exists_1 == 1 & file_exists_2 == 1 & dir_exists == FALSE, ]) # todo find originals from all_files and verify directories

View(files[is.na(file_exists_1) & is.na(file_exists_2) & dir_exists == FALSE, ]) # to move 

View(files[is.na(file_exists_1) & file_exists_2 == 1 & dir_exists == FALSE, ]) # to move


files_to_move <- rbind(files[is.na(file_exists_1) & is.na(file_exists_2) & dir_exists == FALSE, ],
                       files[is.na(file_exists_1) & file_exists_2 == 1 & dir_exists == FALSE, ])

files_to_move[, targetFile := str_c("P:/Takeout-New/", filename_formatted_v2)]
file.copy(from = files_to_move[, SourceFile], to = files_to_move[, targetFile])
files_to_move[, targetFile := str_c(directory, filename_formatted_v2)]
files_to_move <- files_to_move[!(fileName %in% c("14283473-FullA", "20476659-FullA", "6912519-FullA", "6282931DS-Full")), ]
# file.copy(from = files_to_move[, SourceFile], to = files_to_move[, targetFile]) # THIS LINE MESSED UP

#saveRDS(files, file = "P:/Takeout.rds")
#saveRDS(files, file = "P:/Takeout-with-Hash.rds")
#files <- readRDS("P:/Takeout.rds")
# Move Files
# move_files()

temp <- files[is.na(file_exists2)]
temp[, NewSourceFile := str_c("P:/Takeout-New/",filename_formatted_v2)]
file.copy(from = temp$SourceFile, to = temp$NewSourceFile)
