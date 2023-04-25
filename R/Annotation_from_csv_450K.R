#Data matches each probe of Illumina 450K array to a chromosome. 
#File is from https://support.illumina.com/array/array_kits/infinium_humanmethylation450_beadchip_kit/downloads.html -> 
#Infinium HumanMethylation450K v1.2 Product Files -> 
#HumanMethylation450 v1.2 Manifest File (CSV Format).
#Too big to put on Github

#remember to put the file in your working directory
data <- read.table("humanmethylation450_15017482_v1-2.csv", 
                   sep = ",", quote = "", col.names = c(1:33), fill = TRUE)
#move colnames from cells to colnames
colnames(data) <- data[8, ]
#drop the heading
data <- data[-c(1:8), ]
#keep only probes and chromosomes
data <- data.frame(cpg = data$IlmnID, chr = data$CHR)
dim(data)

unique(data$chr)
#drop probes without chromosomes assigned
data <- data[data$chr != "", ]
#drop sex chromosomes (since we won't be doing imputations there)
data <- data[data$chr != "X", ]
data <- data[data$chr != "Y", ]
dim(data)

anno450K <- data
save(list = c("anno450K"), file = "anno450K.RData")
