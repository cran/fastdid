## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----table1, echo=FALSE, message=FALSE, warnings=FALSE, results='asis'--------
tabl <- "
| fastdid | did | control group used |
|-|-|-|
| both | notyettreated | never-treated + not-yet-but-eventually-treated |
| never| nevertreated  | never-treated |
| notyet | | not-yet-but-eventually-treated |
"
cat(tabl) # output the table in a format good for HTML/PDF/docx conversion

## ----table2, echo=FALSE, message=FALSE, warnings=FALSE, results='asis'--------
tabl <- "
| fastdid | did |
|-|-|
| group_time | no aggregation |
|dynamic|dynamic|
|time|calendar|
|group|group|
|simple|simple|
"
cat(tabl) # output the table in a format good for HTML/PDF/docx conversion

