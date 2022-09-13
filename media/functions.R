
get_files <- function(path, recursive = TRUE) {
  require(data.table)
  require(stringr)
  allowed_extensions <- "dng|arw|cr2|jpeg|jpg|png|tiff|tif|gif|mpg|mov|wav|mp4|mkv|avi|thm"
  files <- data.table(SourceFile = list.files(path, pattern = str_c("^.*\\.(",allowed_extensions,"|",toupper(allowed_extensions),"|",")$"), recursive = recursive, full.names = TRUE))
  files[, path := str_remove(SourceFile, "\\/[^\\/]+$")]
  files[, fileName := gsub(str_c(path,"/"), "", SourceFile, fixed=TRUE), by = "SourceFile"] 
  files[, fileExtension := str_to_upper(str_extract(SourceFile, "[^/\\.]+$"))]
  return(files)
}

get_exif <- function(files) {
  require(data.table)
  require(stringr)
  require(exifr)
  require(jsonlite)
  
  exif <- read_exif(files$SourceFile, 
                    tags = c(
                        "FileSize"
                      , "Model"
                      , "FileModifyDate"
                      , "ModifyDate"
                      , "CreateDate"
                      , "DateTimeOriginal"
                      , "FileTypeExtension"
                      , "FirmwareVersion"
                      )
                    )
  setDT(exif)
  
  if( !("FileSize" %in% colnames(exif))) { exif[, FileSize := "Unknown"] }
  if( !("Model" %in% colnames(exif))) { exif[, Model := "Unknown"] }
  if( !("FileModifyDate" %in% colnames(exif))) { exif[, FileModifyDate := NA] }
  if( !("DateTimeOriginal" %in% colnames(exif))) { exif[, DateTimeOriginal := NA] }
  
  # sometimes the output is in base64 so we need to decode to merge back
  exif[str_detect(SourceFile, "base64"), SourceFile := rawToChar(base64_dec(str_remove(SourceFile,"base64:"))), by = "SourceFile"]
  
  return(exif)
}

check_filename_format <- function(all_files) {
  
  allowed_extensions <- "dng|arw|cr2|jpeg|jpg|png|tiff|tif|gif|mpg|mov|wav|mp4|mkv|avi|thm"
  renamed_media_pattern <- str_c(
    "^\\d{4}-\\d{2}-\\d{2}--\\d{2}-\\d{2}-\\d{2}--.+\\.("
    , allowed_extensions, "|", toupper(allowed_extensions)
    , ")$"
  )
  all_files[, filename_check := 0]
  all_files[str_detect(fileName, renamed_media_pattern), filename_check := 1]
}

compute_statistics <- function(exif) {
  return("TODO")
}

extract_dates <- function(files) {
  require(data.table)
  require(stringr)
  
  files[!str_detect(DateTimeOriginal, "\\d"), DateTimeOriginal := NA]
  files[!is.na(DateTimeOriginal), date_time_original := DateTimeOriginal]
  files[is.na(DateTimeOriginal) & !is.na(CreateDate), date_time_original := CreateDate]
  files[is.na(DateTimeOriginal) & is.na(CreateDate) & !is.na(ModifyDate), date_time_original := ModifyDate]
  files[, date_time_original := str_replace_all(date_time_original, "\\s", "--")]
  files[, date_time_original := str_replace_all(date_time_original, "(:|\\/)", "-")]
  files[, date_time_original := str_remove(date_time_original, "\\+.+")]
  
  files[is.na(date_time_original) & str_detect(fileName, "IMG"), date_time_from_filename := str_extract(fileName, "\\d{8}")]
  files[is.na(date_time_original) & str_detect(fileName, "IMG"), date_time_original := str_c(str_sub(date_time_from_filename, 1,4),"-",str_sub(date_time_from_filename, 5,6),"-",str_sub(date_time_from_filename, 7,8))]
  
  files[, date := ymd(str_extract(date_time_original, "^\\d{4}-\\d{2}-\\d{2}"))]
  
  # the original code used the FileModifyDate which is incorrect
  # TODO: check existing DB for mistakes
  #files[, FileModifyDate := str_remove(FileModifyDate, "\\+.+")]
  #files[, date_time_original := str_replace(str_replace_all(DateTimeOriginal,":","-")," ", "--")]
  #files[is.na(DateTimeOriginal), date_time_original := str_replace(str_replace_all(FileModifyDate,":","-")," ", "--")]
}

add_missing_camera_information <- function(files) {
  require(data.table)
  require(stringr)
  
  honor4xstart <- as.Date("2015-06-30")
  samsungs7start <- as.Date("2016-12-01")
  oneplus5start <- as.Date("2017-09-30")
  
  files[, Model:=str_replace_na(Model, replacement = "Unknown")]
  
  files[Model == "Unknown" & str_detect(fileName,"YDXJ"), Model := "YDXJ-2"] # YI 4K Action Camera
  files[Model == "Unknown" & str_detect(fileName,"^GOPR"), Model := "GoProUnknown"] # GoPro
  files[Model == "Unknown" & (str_detect(fileName,"^WhatsApp") | str_detect(fileName, "-WA")), Model := "WhatsAppUnknown"] # WhatsApp
  files[Model == "Unknown" & str_detect(fileName,"^MAH"), Model := "ILCE-6000"] # Sony a6000
  
  files[Model == "Unknown" & str_detect(fileName,"^VID_\\d{8}_") & date_time_original < samsungs7start & date_time_original >= honor4xstart, Model := "Che2-L11"] # Honor 4X
  files[Model == "Unknown" & str_detect(fileName,"^\\d{8}_") & date_time_original < oneplus5start & date_time_original >= samsungs7start, Model := "SM-G930F"] # Samsung Galaxy S7
  files[Model == "Unknown" & (str_detect(fileName,"^VID_\\d{8}_") | str_detect(fileName,"^\\d{4}-\\d{2}-\\d{2}\\s\\d{2}\\.\\d{2}\\.\\d{2}")) & date_time_original >= oneplus5start, Model := "ONEPLUS-A5000"] # ONEPLUS-A5000

  files[, Model := str_replace_all(Model, "\\s", "-")]
}

image_dhash <- function(SourceFile) {
  require(OpenImageR)
  require(stringr)
  temp <- NA
  tryCatch(               
    # Specifying expression
    expr = {                     
      temp <- readImage(SourceFile)
    },
    # Specifying error message
    error = function(e){
      temp <- NA
      print(str_c("There was an error for: ", SourceFile))
    }
  )
  if (length(temp) > 1) {
    temp <- rgb_2gray(temp)
    temp <- dhash(temp, hash_size = 8, MODE = 'hash', resize = "bilinear")
  }
  return(temp)
}

new_file_name <- function(files, version = "latest") {
  require(data.table)
  require(stringr)
  if (version == "latest" | version == "all") {
    # format: yyyy-mm-dd--hh-mm-ss--camera-model--original-name.extension
    files[, filename_formatted_v2 := str_c(date_time_original, "--", Model, "--", str_remove_all(fileName, "[^[:alnum:]]"), ".", FileTypeExtension)]
  }
  if (version == "v1" | version == "all") {
    # format: yyyy-mm-dd--hh-mm-ss--camera-model.extension
    # not working if continuous shooting or duplicates
    files[, filename_formatted_v1 := str_c(date_time_original, "--", Model, ".", FileTypeExtension)]
    files[, special := str_extract(SourceFile, "(?<=ILCE-6000--).*(?=\\.JPG)")]
    files[, special := str_extract(SourceFile, "(?<=Canon-EOS-550D--).*(?=\\.JPG)")]
    files[, special := str_extract(SourceFile, "Bokeh")]
    files[!is.na(special), filename_formatted_v1 := str_c(date_time_original, "--", Model, "--", special, ".", FileTypeExtension)]
  }
}

check_duplicates <- function(files, version = "latest") {
  require(data.table)
  require(stringr)
  if (version == "latest" | version == "all") {
    files[, duplicate_first_pass := duplicated(filename_formatted_v2)]
    files[, fileName := gsub(str_c(".", tolower(FileTypeExtension)), "", fileName, fixed=TRUE), by = "SourceFile"]
    files[, fileName := gsub(str_c(".", FileTypeExtension), "", fileName, fixed=TRUE), by = "SourceFile"]
    files[duplicate_first_pass == TRUE, filename_formatted_v2 := str_c(date_time_original, "--", Model, "--", str_remove_all(fileName, "[^[:alnum:]]"), "--",FileSize, ".", FileTypeExtension)]
    files[, duplicate_second_pass := duplicated(filename_formatted_v2)]
  }
  if (version == "v1" | version == "all") {
    files[, dup := duplicated(filename_formatted_v1)]
    files[, fileName := gsub(str_c(".", tolower(FileTypeExtension)), "", fileName, fixed=TRUE), by = "SourceFile"]
    files[, fileName := gsub(str_c(".", FileTypeExtension), "", fileName, fixed=TRUE), by = "SourceFile"]
    files[dup==TRUE, filename_formatted_v1 := str_c(date_time_original, "--", Model, "--", FileSize, ".", FileTypeExtension)]
    files[, dupbis := duplicated(filename_formatted_v1)]
  }
}

build_directory_index <- function(library_path) {
  directories <- data.table(directory = list.dirs(library_path, recursive = FALSE))
  directories[, date_start := ymd(str_extract(directory, "\\d{4}-\\d{2}-\\d{2}"))]
  directories[, duration := str_extract(directory, "(?<=\\d{4}-\\d{2}-\\d{2}--P)[^\\s]+")]
  directories[, duration_n := as.numeric(str_extract(duration, "\\d+"))]
  directories[str_detect(duration, "Y"), duration_days := duration_n * 365]
  directories[str_detect(duration, "M"), duration_days := duration_n *  30]
  directories[str_detect(duration, "W"), duration_days := duration_n *   7]
  directories[str_detect(duration, "D"), duration_days := duration_n *   1]
  directories[, date_end := date_start + duration_days]
  return(directories)
}

assign_directory <- function(files, directories, library_path) {
  n <- nrow(files)
  for (i in 1:n) {
    import_date <- files[i, date]
    temp <- directories[date_start <= import_date & date_end >= import_date, ]$directory
    if (length(temp) != 1) {
      temp <- directories[date_start == import_date, ]$directory
      if (length(temp) != 1) {
        temp <- str_c(library_path, "/", import_date)
      }
    }
    files[i, directory := temp]
  }
}

move_files <- function() {
  files[, filename_new_path :=  str_c(directory, "/", filename_formatted_v2)]
  m <- nrow(files)
  for (i in 1:m) {
    if (!dir.exists(files[i, directory])) {
      dir.create(files[i, directory])
    }
    file.copy(from = files[i, filename_full_path], to = files[i, filename_new_path])
  }
}
