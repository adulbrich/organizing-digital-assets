# Organizing Digital Assets

Ordering (optional) elements in file or folder names:

1. [ISO Date and Time or Duration](https://en.wikipedia.org/wiki/ISO_8601) (adjusted for compatibility)
2. Description (folder name, file name, camera model, etc.)
3. Extension

Do not use underscores or spaces. Use double-dashes instead. It improves readability.

Prefer lowercase, in particular for web project, because of URLs.

## Folder Structure and Naming

My organisation structure is losely based on the [PARA Method](https://fortelabs.co/blog/para/).
At the root of my home folder, I have the following:

- `Archive`
- `Areas`
- `Inbox`
- `Pictures and Videos`
- `Projects`
- `Resources`
- `Work`

### Projects

The `Projects` folder contains all _active_ projects (i.e. projects that are not finished nor cancelled). Projects, per definition, will not run forever, and should have a duration.
Everything related to that project (but code) will be in that folder. Code should be in a git repository.

Project folders should be written as:

`<iso-date>--<iso-duration> <project-name>`

where:

- `<iso-date>` is the [date](https://en.wikipedia.org/wiki/ISO_8601#Calendar_dates) in the format `YYYY-MM-DD`,
- `<iso-duration>` is the [duration](https://en.wikipedia.org/wiki/ISO_8601#Durations) starting from `<iso-date>` in the format `PnYnMnDTnHnMnS`,
- `<project-name>` is the name of the project, it can be multiple capitalized words, separated by spaces.

The period starts with `P` followed by one or more digits (the amount of) and then the unit (`D` for days, `W` for weeks, etc.)

Notes:

- The duration serves as estimate for how long the project should or will take.
- The duration should be updated whenever the project is archived.
- We use spaces after the duration and for the project name for readability and search.
- For maximum compatibility, it would be better to separate duration and project name by a double dash `--` and spaces in the project name by a simple dash `-`.

Examples:

- `2021-10-22--P1W My Cool Project`
- `2019-07-25--P2W Travel Columbia`
- `2021-10-23--P1D Another Cool Unfinished project`
- `2018-98-04--P3W--Travel-Iran`

### Areas and Resources

The `Areas` folder contains all things personal that do not have an end date, such as:

- `Finance`
  - `Taxes`: one folder per fiscal year per country, includes all documents (salary certificates, bank statements, etc.)
  - `Invoices and Receipts`: all invoices or receipts from any institutions (retail or otherwise)
  - `Admin`: all administrative documents from financial institutions that are not related to taxes (account openings and closures, terms and conditions, pension statements, etc.)
- `Insurance`
  - `<iso-date>--<iso-duration> <insurance-type> <insurer> <policy-number>`: one folder per insurance contract, with optional duration
- `Home`
  - `<iso-date>--<iso-duration> <address-or-alias>`: one per home, contains everything related to that specific home, but insurance
- `Transport`
  - `<type-of-transport> <car-plate-or-chassis-or-customer-number> <alias>`: one per mode of transportation, contains all documents (contracts, certificates, etc) related to that specific transport, but insurance
- `Education`: diplomas, certificates, etc.
- `Identity`: everything related to passports, identity cards, household, visas, birth certificates, etc.
- `Health and Sports`: blood reports, genetics, vaccination, certificates, sport competitions, dentist reports, etc.
- `Work`: work contracts, job descriptions, agreements, etc.
- `Writings`

The `Resources` folder contains notes, articles, books, and other references on specific topics of interest, such as (non-exhaustive list):

- `Aging`
- `Breathing`
- `Consulting Interviews`
- `Dance Lindy Hop`
- `Dance Salsa`
- `Data Management`
- `Leadership and Management`
- `Medicine`
- `Minimalism`
- `Star Wars`

Notes:

- Area folders should be mutually exclusive.
- Resource folders should be mutually exclusive.
- Resource folders can and should be re-structured whenever necessary to avoid overlapping.
- For Resource and Area folders, you can replace spaces by a simple dash `-`.
- `Insurance` sub-items could be moved to `Home`, `Transport`, and `Health`.

### Pictures and Videos

Pictures and videos taken as memories have their own dedicated folder structure because of the sheer amount of files.

The `Pictures and Videos` folder contains sub-folders with the following structure:

`<iso-date>--<iso-duration>--<alias>`

where:

- `<iso-date>` is the [date](https://en.wikipedia.org/wiki/ISO_8601#Calendar_dates) in the format `YYYY-MM-DD`,
- (optional) `<iso-duration>` is the [duration](https://en.wikipedia.org/wiki/ISO_8601#Durations) starting from `<iso-date>` in the format `PnYnMnDTnHnMnS`,
- (optional) `<alias>` is the alias for that event, journey or travel, it can be multiple capitalized words, separated by dashes.

Examples:

- `2021-02-12`
- `2021-02-13`
- `2018-98-04--P3W--Travel-Iran`
- `2020-08-03--Hike-Mont-Tendre`
- `2014-06-30--P19D--Central-Asia` (so 19 days starting on June 30, 2014)

Notes:

- While a travel project (e.g. `2018-98-04--P3W--Travel-Iran`) will contain all documents (such as travel passes, planning, etc.) for that specific journey, all media memories will be stored in a corresponding folder in the `Pictures and Videos` folder.

### Inbox

TODO
### Work

TODO
### Archive

TODO
### Code

Code projects should be hosted in a git repository (such as Github) and not contain any spaces.
If a code project is not hosted in a git repository for any reasons, it is best that the path to that folder does not contain spaces.

## File Names

Pictures and Videos

Format: `yyyy-mm-dd--hh-mm-ss--camera-model-name.extension`

Relevant EXIF Tags:

* Model
* DateTimeOriginal
* FileTypeExtension

Substitutions:

* semi-colons `:` by dashes `-` in DateTimeOriginal
* spaces by dashes `-` in Model

Example: `2020-11-21--19-42-10--oneplus-a5000.jpg`

**What to do if the time zone is wrong?**
Quantitatively look at the time distribution in the folder. 

## Media Toolbox

### Background and Objectives

I gathered quite a lot of images and videos over the years, from traveling to events.

- I noticed that images taken with my DSLR had often the wrong time because I was traveling in another time zone and did not change the camera time.
- Images taken with my phone were usually correct but on planes.
- Sorting images by name was a struggle because they used different naming conventions.
- Sorting by creation date was not always working because of above.
- Videos did not store the same Exif metadata. Images would usually have a `DateTimeOriginal` while videos would have a `FileModifyDate`.

## Methodology

### Identify the Time Difference (if any)

The first step is to identify if the DSLR was misconfigured and the times were incorrect. Two options:

1. Check the `DateTimeOriginal` manually (e.g. with Exiftool) and see if something is amiss.
2. Extract the time in decimal hours from all pictures and compare the median of phone vs DSLR. The hypothesis is that the phone has the correct time.

This allows me to figure the time difference of the DSLR. I double-check that with the time difference between my home country and the country I was traveling to at that time.

Finding multiple pictures taken at the same time with both phone and DSLR is the best way to make sure the times match.

### Correct the Time Difference (if any)

The second step is to run e.g. [Exiftool](https://exiftool.org/) on the images that have the wrong times. 

For example to adjust all pictures taken with a canon in the current directory by +3 hours, you can run:

```bash
exiftool -m -if "`$Make eq 'Canon'" "-DateTimeOriginal+=0:0:0 3:0:0" .
```

`-m` removes warning messages for misaligned exif data e.g. while the `-if` statement check for picture taken with a Canon DSLR.

You can swap `DateTimeOriginal` with another property, for example `FileModifyDate` and you can change `+=` to `-=` if you need to substract hours. The day change will happen automatically if there is one.

Finally, you can add a filter on the extension. For example by adding `-ext mp4`, only MP4 files will be modified.

### Standardize File Names

Thirdly, I wanted to have a nice and easily readable file name. I figured I wanted to know the following:

- Date taken
- Time taken
- Model of the camera
- File type

The file name must be compatible with most file systems or cloud storages, so no special characters.

I ended up choosing a modified [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) formatting, to which I added the camera model:

`YYYY-MM-DD--hh-mm-ss--Model.FileTypeExtension`

It would look like this:  `2014-07-01--01-14-48--Canon-EOS-550D.JPG`

This allowed me to sort the images and videos as well chronologically, based on file name. I would use either the `DateTimeOriginal` or `FileModifyDate` depending on what is most relevant.

Some phones would not store their model for videos, so I have a mapping table with the dates when I had a specific phone.

## Storage

Once all files are formatted and organized, I backup the files on an external hard drive and on a cloud backup storage (for which I have the encryption keys).
I then upload the files to a dedicated cloud store such as Adobe Lightroom CC or Google Photos or Microsoft OneDrive.
