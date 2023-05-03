library(ChAMP)
library(minfi)

path <- "PUT YOUR PATH HERE"
setwd(path)

#change geo id for the second betaaset
geo <- "GSE199057"
gset <- readRDS(paste(geo, "subset.RDS", sep = "_")) 

MSet <- preprocessRaw(gset)
remove(gset)
qc <- getQC(MSet)
plotQC(qc)
densityPlot(MSet)

ratioSet <- ratioConvert(MSet, what = "beta")
remove(MSet)
ggset <- mapToGenome(ratioSet)
remove(ratioSet)

snps <- getSnpInfo(ggset)
ggset <- addSnpInfo(ggset)
ggset <- dropLociWithSnps(ggset)

beta <- getBeta(ggset)
remove(ggset)
dim(beta)

#load annotation. Note that this one is already filtered for sex chromosomes
load("annoEPIC.Rdata")
beta <- beta[rownames(beta) %in% annoEPIC$cpg, ]
dim(beta)



