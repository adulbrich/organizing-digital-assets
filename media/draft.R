
import_files_exif <- read_exif(
  path = import_files[]$filename_full_path,
  tags = c(
    "FileSize"
    , "Model"
    , "FileModifyDate"
    , "DateTimeOriginal"
    , "CreateDate"
    , "ModifyDate" # e.g.
    , "FileTypeExtension"
    , "FirmwareVersion")
)
setDT(import_files_exif)

import_files_exif[, .N, by=c("FileTypeExtension")]

missing_dates <- import_files_exif[is.na(DateTimeOriginal) & is.na(CreateDate) & is.na(ModifyDate) & FileTypeExtension != "JSON", ]

####

folder_1 <- ""
folder_2 <- ""

import_files_1 <- data.table(filename_full_path = list.files(folder_1, recursive = TRUE, full.names = TRUE))
import_files_1[, filename_original := str_extract(filename_full_path, str_c("(?<=^", folder_1, "/).+$"))]

import_files_2 <- data.table(filename_full_path = list.files(folder_2, recursive = TRUE, full.names = TRUE))
import_files_2[, filename_original := str_extract(filename_full_path, str_c("(?<=^", folder_2, "/).+$"))]

import_files_2[!(filename_original %in% import_files_1$filename_original), ]

##
root_folder <- "" # where all media is stored by date
import_folder <- "" # where the new media is located

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
import_files[, date := ymd(str_extract(filename_original, "^\\d{4}-\\d{2}-\\d{2}"))]

import_files <- merge(
    import_files,
    all_files[, .(filename_original, file_exists = 1)],
    by = c("filename_original"),
    all.x = TRUE
)

root_directories <- all_directories[!str_detect(directory, "/"), ]
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
    temp <- root_directories[date_start <= import_date & date_end >= import_date, ]$directory
    if (length(temp) != 1) {
        temp <- root_directories[date_start == import_date, ]$directory
        if (length(temp) != 1) {
            temp <- str_c(import_date)
            # if (dir.exists(temp)) {
            #     stop("the directory already exists")
            # } else {
                # dir.create(temp)
            # }
        }
    }
    import_files[i, directory := temp]
}

import_files[, new_directory := str_c(root_folder, "/", directory)]
import_files[, filename_new_path :=  str_c(new_directory, "/", filename_original)]

m <- nrow(import_files)
for (i in 1:m) {
    if (!dir.exists(import_files[i, new_directory])) {
        dir.create(import_files[i, new_directory])
    }
    file.copy(from = import_files[i, filename_full_path], to = import_files[i, filename_new_path])
}