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

root_folder <- "/Users/alex/Downloads/test" # where all media is stored by date
import_folder <- "/Users/alex/Downloads/test" # where the new media is located

# List Import Images
allowed_extensions <- "dng|arw|cr2|jpeg|jpg|png|tiff|tif|mov|wav|mp4|mkv|avi"
renamed_media_pattern <- str_c(
    "^\\d{4}-\\d{2}-\\d{2}--\\d{2}-\\d{2}-\\d{2}--.+\\.("
    , allowed_extensions, "|", toupper(allowed_extensions)
    , ")$"
)
import_files <- data.table(filename_full_path = list.files(import_folder, recursive = TRUE, full.names = TRUE))
import_files[, filename_original := str_extract(filename_full_path, str_c("(?<=^", import_folder, "/).+$"))]
import_files[, filename_check := 0]
import_files[str_detect(filename_original, renamed_media_pattern), filename_check := 1]

# Read EXIF Data from Files
import_files_exif <- read_exif(
    path = import_files$filename_full_path,
    tags = c(
        "FileSize"
        , "Model"
        , "FileModifyDate"
        , "DateTimeOriginal"
        , "FileTypeExtension"
        , "FirmwareVersion")
)
setDT(import_files_exif)
setnames(import_files_exif, "SourceFile", "filename_full_path")
setnames(import_files_exif, "Model", "camera_model")
setnames(import_files_exif, "DateTimeOriginal", "date_time_original")
import_files <- merge(
    import_files,
    import_files_exif[!is.na(date_time_original), .(filename_full_path, camera_model, date_time_original)],
    by = "filename_full_path"
)
rm(import_files_exif)

# Format EXIF Data
import_files[, camera_model := str_replace_all(camera_model, "\\s", "-")]
import_files[, date_time_original := str_replace_all(date_time_original, "\\s", "--")]
import_files[, date_time_original := str_replace_all(date_time_original, ":", "-")]
import_files[, date := ymd(str_extract(date_time_original, "^\\d{4}-\\d{2}-\\d{2}"))]
# TODO: manage images taken in quick succession, could we hash the image to differentiate it?

# Rename Images
# TODO: rename images for which filename_check == 0

# List Root Directories
root_directories <- data.table(directory = list.dirs(root_folder))
root_directories[, date_start := ymd(str_extract(directory, "\\d{4}-\\d{2}-\\d{2}"))]
root_directories[, duration := str_extract(directory, "(?<=\\d{4}-\\d{2}-\\d{2}--P)[^\\s]+")]
root_directories[, duration_n := as.numeric(str_extract(duration, "\\d+"))]
root_directories[str_detect(duration, "Y"), duration_days := duration_n * 365]
root_directories[str_detect(duration, "M"), duration_days := duration_n *  30]
root_directories[str_detect(duration, "W"), duration_days := duration_n *   7]
root_directories[str_detect(duration, "D"), duration_days := duration_n *   1]
root_directories[, date_end := date_start + duration_days]

# Create Folders and Move Images
n <- nrow(import_files)
for (i in 1:n) {
    import_date <- import_files[i, date]
    root_directories[date_start <= import_date & date_end >= import_date, ]
    # to be continued
}