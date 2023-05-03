library(GEOquery)
library(stringi)
library(filesstrings)

#download GEO object
geo <- "GSE199057"
gse <- getGEO(geo, GSEMatrix = TRUE)
#get phenotype data - sample sheet
pd <- pData(gse[[1]])
#choose only healthy patients
pd_healthy <- pd[pd$`disease state:ch1` == "Healthy", ]
pd_healthy <- pd_healthy[!grepl("Control", pd_healthy$title), ]
table(pd_healthy$`age:ch1`)
table(pd$`Sex:ch1`)
table(pd_healthy$`race:ch1`)

#get raw data - idats, processed beta matrix, etc.
getGEOSuppFiles(geo)

#decompress idats
untar(paste(geo, "/", geo, "_RAW.tar", sep = ""), exdir = paste(geo, "/idat", sep = ""))
#list files
head(list.files(paste(geo, "/idat", sep = ""), pattern = "idat"))
idatFiles <- list.files(paste(geo, "/idat", sep = ""), pattern = "idat.gz$", full = TRUE)

#which are files are of healthy patients?
healthy_ids <- stri_sub(idatFiles, from = 16, to = 25) %in% rownames(pd_healthy)
idatFiles_healthy <- idatFiles[healthy_ids]
file.move(idatFiles_healthy, paste(geo, "/idat_healthy", sep = ""))

#decompress individual idat files
sapply(idatFiles_healthy, gunzip, overwrite = TRUE)

#read idats of interest and create RGSet
RGSet <- read.metharray.exp(paste(geo, "/idat_healthy", sep = ""))
saveRDS(RGSet, paste(geo, "subset.RDS", sep = "_"))
