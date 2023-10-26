path <- "ADD_YOUR_PATH_HERE"
setwd(path)

library(parallel)
library(ggplot2)
library(methyLImp2)
library(dplyr)

#please download the dataset from here
#https://uio-my.sharepoint.com/:u:/g/personal/annapla_uio_no/Ec0RVBJ3HBtKrh316y54DwgBgZq9IumepY0sH9eEvkqctg?e=4NYcpl
#and add into your folder
#load("68_samples.Rdata")
#generate NAs
#print("Generating artificial NAs...")
#lambda <- 10
#beta_with_nas <- na_positions <- vector(mode = "list", length = nruns)
#for (i in 1:nruns) {
#  res <- generateMissingData(beta, lambda = lambda)
#  beta_with_nas[[i]] <- res$beta_with_nas
#  na_positions[[i]] <- res$na_positions
#}
#save(list = c("beta", "beta_with_nas", "na_positions"), 
#     file = "beta_for_ncores.Rdata")
#I already generated NAs so I load this file
load("beta_for_ncores.Rdata")

ncores <- dim(beta)[1]
nprobes <- dim(beta)[2]

filename_save <- "perf_ncores.Rdata"

ncores_vec <- c(9:1)
nruns <- 5

perf_ncores <- matrix(0, nrow = length(ncores_vec) * nruns, ncol = 6)
colnames(perf_ncores) <- c("ncores", "run", 
                           "time_sec", "time_min", 
                           "RMSE", "MAE")
perf_ncores[, "ncores"] <- rep(ncores_vec, each = nruns)
perf_ncores[, "run"] <- rep(c(1:nruns), length(ncores_vec))

ind <- 1
for(s in 1:length(ncores_vec)) {
  timestamp()
  curr_ncores <- ncores_vec[s]
  print(paste("Computing with", curr_ncores, "cores..."))
  
  for (i in 1:nruns) {
    timestamp()
    print(paste0("Run ", i))
    
    curr_data_with_NAs <- beta_with_nas[[i]]
    curr_na_positions <- na_positions[[i]]
    
    curr_time <- system.time({
      beta_estimated <- methyLImp2(curr_data_with_NAs, type = "EPIC",
                                   ncores = curr_ncores)
    })[3]
    
    perf_ncores[ind, "time_sec"] <- curr_time
    
    #performance evaluation
    curr_perf <- evaluatePerformance(beta, beta_estimated, 
                                     curr_na_positions)
    perf_ncores[ind, "RMSE"] <- curr_perf["RMSE"]
    perf_ncores[ind, "MAE"] <- curr_perf["MAE"]
    
    save(list = c("perf_ncores"), file = filename_save)
    gc()
    
    ind <- ind + 1
  }
  
  message("Finished running with ", curr_ncores, "cores.") 
  print(perf_ncores[(5 * s - 4):(5 * s), ])
}

perf_ncores <- as.data.frame(perf_ncores)
perf_ncores$time_min <- perf_ncores$time_sec / 60

perf_ncores_mean <- perf_ncores %>%
  group_by(ncores) %>%
  summarize(across(time_sec:MAE, mean))
print(perf_ncores_mean)

perf_ncores_sd <- perf_ncores %>%
  group_by(ncores) %>%
  summarize(across(time_sec:MAE, sd))
print(perf_ncores_sd)

ggplot(perf_ncores_mean, aes(x = ncores, y = time_min)) +
  geom_point(size = 2.5) +
  geom_line(linewidth = 0.8) +
  scale_x_continuous(breaks = seq(0, 9, by = 1)) +
  scale_y_continuous(breaks = seq(0, 130, by = 10),limits = c(0, 120)) +
  xlab("Number of cores") + 
  ylab("Time in minutes") 
