# install.packages(c("exifr", "data.table", "stringr", "jsonlite", "lubridate"))
library(stringr)
library(data.table)
library(exifr)
library(lubridate)

# NAS Local Database
root_folder <- "/Pictures/Originals" # where all media is stored by date
db_store <- "" # where to store the database

# List All Media (Pictures and Videos)
allowed_extensions <- "heic|dng|arw|cr2|jpeg|jpg|png|tiff|tif|mov|wav|mp4|mkv|avi"
renamed_media_pattern <- str_c(
    "^\\d{4}-\\d{2}-\\d{2}--\\d{2}-\\d{2}-\\d{2}--.+\\.("
    , allowed_extensions, "|", toupper(allowed_extensions)
    , ")$"
)
all_files <- data.table(filename_full_path = list.files(root_folder, recursive = TRUE, full.names = TRUE))
all_files[, directory := str_extract(filename_full_path, str_c("(?<=^", root_folder, "/).+(?=/[^/]+$)"))]
all_files[, filename_original := str_extract(
    filename_full_path,
    str_c(
        "(?<=^"
        , root_folder
        , "/"
        , directory
        , "/).+$"
    )
)]
all_files[is.na(directory), filename_original := str_extract(
    filename_full_path,
    str_c(
        "(?<=^"
        , root_folder
        , "/).+$"
    )
)]
all_files[, filename_check := 0]
all_files[str_detect(filename_original, renamed_media_pattern), filename_check := 1]
all_files[, filetype_extension := str_to_lower(str_extract(
    filename_original,
    str_c("(", allowed_extensions, "|", toupper(allowed_extensions), ")$")
))]
all_files[, all_filetype_extension := str_to_lower(str_extract(
    filename_original,
    "\\..{1,4}$")
)]

# Statistics
all_files[, .N, by = filetype_extension]
all_files[, .N, by = all_filetype_extension]
all_files[, .N, by = filename_check]
all_files[, .N, by = directory]

View(all_files[filename_check == 0, ])
# TODO: for accepted filetype extensions and existing exif data: rename

# Find Duplicates
duplicate_index <- duplicated(all_files$filename_original)
duplicate_files <- all_files[filename_original %in% all_files[duplicate_index, filename_original], ]

# Save RDS
# TODO: Save the date of the update in the rds file name
saveRDS(
    all_files,
    file = str_c(
        db_store
        , today()
        , "-all-media-files.rds"
    )
)
fwrite(
    all_files,
    file = str_c(
        db_store
        , today()
        , "-all-media-files.csv"
    )
)

# Identify Empty Directories
all_directories <- data.table(foldername_full_path = list.dirs(root_folder, recursive = TRUE, full.names = TRUE))
all_directories[, directory := str_extract(foldername_full_path, str_c("(?<=^", root_folder, "/).+(?=$)"))]

n_files_per_directory <- all_files[, .N, by = directory]

all_directories <- merge(
    all_directories,
    n_files_per_directory,
    by = "directory",
    all.x = TRUE
)

# find missing jpegs when raw files are present
raw_folders <- all_directories[str_detect(directory, "RAW"), str_remove(foldername_full_path, "/RAW")]
View(all_directories[foldername_full_path %in% raw_folders, ])

# find empty directories
empty_dirs <- c()
for (i in c(all_directories[is.na(N), foldername_full_path])) {
    if (all_directories[str_detect(foldername_full_path, i), .N] == 1) {
        empty_dirs <- c(empty_dirs, i)
    }
}
