# install.packages(c("exifr", "data.table", "stringr", "jsonlite", "lubridate"))
library(stringr)
library(data.table)
library(exifr)
library(lubridate)

# draft, code not tested

# this script sorts images from an "import" folder into the library-of-truth "root" folder
# 1. list all images in root folder
# 2. check if the images adhere to the right naming convention
# 2.2. if not, renames images, based on exif data
# 3. list all folders in root
# 4. for each folder:
# 4.1. list start date
# 4.2. if there is a period, list end date
# 5. for a given image:
# 5.1. check date and see if a folder already exist for it (either exact date or within range)
# 5.2. if folder exists, move image
# 5.3. if folder does not exist, create new specific date folder, then move image

root_folder <- "" # where all media is stored by date
import_folder <- "afp://alexandria.local/home/Inbox/Camera Uploads/" # where the new media is located

allowed_extensions <- "dng|arw|cr2|jpeg|jpg|png|tiff|tif|mov|wav|mp4|mkv|avi"
renamed_media_pattern <- str_c(
    "^\\d{4}-\\d{2}-\\d{2}--\\d{2}-\\d{2}-\\d{2}--.+\\.("
    , allowed_extensions, "|", toupper(allowed_extensions)
    , ")$"
)

import_files <- data.table(filename_original = list.files(import_folder, recursive = TRUE))
import_files[, filename_check := 0]
import_files[str_detect(filename_original, renamed_media_pattern), filename_check := 1]

root_directories <- data.table(directory = list.dirs(root_folder))
root_directories[, date_start := str_extract(directory, "\\d{4}-\\d{2}-\\d{2}")]
root_directories[, duration := str_extract(directory, "(?<=\\d{4}-\\d{2}-\\d{2}--P).+(?=\\s)")]
root_directories[, duration_n := str_extract(duration, "\\d+")]
root_directories[str_detect(duration, "Y"), duration_days := duration_n * 365]
root_directories[str_detect(duration, "M"), duration_days := duration_n *  31]
root_directories[str_detect(duration, "W"), duration_days := duration_n *   7]
root_directories[str_detect(duration, "D"), duration_days := duration_n *   1]
root_directories[, date_end := date_start + duration_days]