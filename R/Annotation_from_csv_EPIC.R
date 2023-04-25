#Data matches each probe of Illumina EPIC array to a chromosome. 
#File is from https://support.illumina.com/array/array_kits/infinium-methylationepic-beadchip-kit/downloads.html -> 
#Infinium MethylationEPIC v1.0 Product Files (Legacy BeadChip) -> 
#Infinium MethylationEPIC v1.0 B5 Manifest File (CSV Format).
#File is too big to put on Github

#remember to put the file in your working directory
data <- read.table("infinium-methylationepic-v-1-0-b5-manifest-file.csv", 
                   sep = ",", quote = "", col.names = c(1:52), fill = TRUE)

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

annoEPIC <- data
save(list = c("annoEPIC"), file = "annoEPIC.RData")
