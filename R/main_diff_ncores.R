path <- "ADD_YOUR_PATH_HERE"
setwd(path)

library(parallel)
library(ggplot2)
library(methyLImp2)

#please download the dataset from here
#https://uio-my.sharepoint.com/:u:/g/personal/annapla_uio_no/Ec0RVBJ3HBtKrh316y54DwgBgZq9IumepY0sH9eEvkqctg?e=4NYcpl
#and add into your folder
load("68_samples.Rdata")
ncores <- dim(beta)[1]
nprobes <- dim(beta)[2]

filename <- "perf_ncores.Rdata"

ncores_vec <- c(9:1)
nruns <- 5

perf_ncores <- matrix(0, nrow = length(ncores_vec), ncol = 5)
colnames(perf_ncores) <- c("ncores", "time_sec", "time_min", "RMSE", "MAE")
perf_ncores[, 1] <- ncores_vec

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
load("beta_for_ncores.Rdata")

for (i in 1:nruns) {
  timestamp()
  print(paste0("Run ", i))
  
  curr_data_with_NAs <- beta_with_nas[[i]]
  curr_na_positions <- na_positions[[i]]
  
  for (s in 1:length(ncores_vec)) {
    timestamp()
    curr_ncores <- ncores_vec[s]
    print(paste("Computing with", curr_ncores, "cores..."))
  
    curr_time <- system.time({
      beta_estimated <- methyLImp2(curr_data_with_NAs, type = "EPIC",
                                   ncores = curr_ncores)
    })[3]
    
    perf_ncores[s, "time_sec"] <- perf_ncores[s, "time_sec"] + curr_time
    
    #performance evaluation
    curr_perf <- evaluatePerformance(beta, beta_estimated, 
                                     curr_na_positions)
    perf_ncores[s, "RMSE"] <- perf_ncores[s, "RMSE"] + curr_perf["RMSE"]
    perf_ncores[s, "MAE"] <- perf_ncores[s, "MAE"] + curr_perf["MAE"]
  }
  
  save(list = c("perf_ncores"), file = filename)
  gc()
}

perf_ncores[ , c("time_sec", "RMSE", "MAE")] <- 
  perf_ncores[ , c("time_sec", "RMSE", "MAE")] / nruns
perf_ncores <- as.data.frame(perf_ncores)
perf_ncores$time_min <- perf_ncores$time_sec / 60
save(list = c("perf_ncores"), file = filename)
print(perf_ncores)

ggplot(perf_ncores, aes(x = ncores, y = time_min)) +
  geom_point(size = 2) +
  geom_line(linewidth = 0.8) +
  scale_x_continuous(breaks = seq(0, 9, by = 1)) +
  scale_y_continuous(breaks = seq(0, 150, by = 20)) +
  xlab("Number of cores") + 
  ylab("Time in minutes") +
  theme_light(base_size = 16)
