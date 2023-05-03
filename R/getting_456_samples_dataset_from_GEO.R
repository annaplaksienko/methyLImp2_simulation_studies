library(GEOquery)
library(stringi)
library(filesstrings)
library(minfi)

path <- "PUT YOUR PATH HERE"
setwd(path)

#download GEO object
geo <- "GSE158063"
gse <- getGEO(geo, GSEMatrix = TRUE)
#get phenotype data - sample sheet
pd_full <- pData(gse[[1]])
#the dataset is big ans heterogenouos, so we reduce it a little
#first, choose only spotaneous conception
table(pd_full$`art treatment status (0 = spontaneous; 1 = assisted reproduction):ch1`)
pd <- pd_full[pd_full$`art treatment status (0 = spontaneous; 1 = assisted reproduction):ch1` == "0", ]
#now, choose only one ethnicity (we choose the biggest)
t_eth <- table(pd$`maternal ethnicity (0 = chinese; 1 = indian; 2 = malay):ch1`)
names(t_eth) <- c("chinese", "indian", "malay")
t_eth
pd <- pd[pd$`maternal ethnicity (0 = chinese; 1 = indian; 2 = malay):ch1` == "0", ]
#limit age (since methylation varies a lot for different age groups)
age <- as.numeric(pd$`maternal age at delivery (years):ch1`)
hist(age, xlab = "", main = "age at delivery")
pd <- pd[age > 20 & age < 40, ]
#check if sex balanced sample-size wise
t_sex <- table(pd$`child sex (male = 0; female = 1):ch1`)
names(t_sex) <- c("male", "female")
t_sex
#save
save(list = c("pd", "pd_full"), file = paste(geo, "_phenodata.Rdata", sep = ""))


#download raw data - idats, processed beta matrix, etc.
options(timeout = 60000)
getGEOSuppFiles(geo)

#decompress idats
untar(paste(geo, "/", geo, "_RAW.tar", sep = ""), exdir = paste(geo, "/idat", sep = ""))
#list files
head(list.files(paste(geo, "/idat", sep = ""), pattern = "idat"))
idatFiles <- list.files(paste(geo, "/idat", sep = ""), pattern = "idat.gz$", full = TRUE)

#which are files of interest?
ids <- stri_sub(idatFiles, from = 16, to = 25) %in% rownames(pd)
sum(ids) / 2 == dim(pd)[1]
idatFiles <- idatFiles[ids]
file.move(idatFiles, paste(geo, "/idat_subset", sep = ""))

#decompress individual idat files
idatFiles <- list.files(paste(geo, "/idat_subset", sep = ""), pattern = "idat.gz$", full = TRUE)
sapply(idatFiles, gunzip, overwrite = TRUE)
idatFiles <- list.files(paste(geo, "/idat_subset", sep = ""), pattern = "idat$", full = TRUE)

#read idats of interest and create RGSet
RGSet <- read.metharray.exp(paste(geo, "/idat_subset", sep = ""))
saveRDS(RGSet, paste(geo, "subset.RDS", sep = "_"))

