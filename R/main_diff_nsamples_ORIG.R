path <- "ADD_YOUR_PATH_HERE"
setwd(path)

library(parallel)
library(ggplot2)
#library("devtools")
#install_github("pdilena/methyLImp")
library(methyLImp)

#please check the file main_diff_nsamples.R for the process of data generation
load("beta_for_nsamples.Rdata")

nsamples <- dim(beta)[1]
nprobes <- dim(beta)[2]

filename <- "perf_nsamples_ORIG.Rdata"

samp_size_vec <- c(9, 17)
nruns <- 5

perf_orig_nsamples <- matrix(0, nrow = length(samp_size_vec), ncol = 5)
colnames(perf_orig_nsamples) <- c("nsamples", "time_sec", "time_min", "RMSE", "MAE")
perf_orig_nsamples[, 1] <- samp_size_vec

for (s in 1:length(samp_size_vec)) {
  timestamp()
  curr_data <- beta_subsampled[[s]]
  curr_samp_size <- samp_size_vec[s]
  print(paste("Computing with", curr_samp_size, "samples..."))

  for (i in 1:nruns) {
    timestamp()
    print(paste0("Run ", i))
    
    curr_data_with_NAs <- beta_with_nas[[s]][[i]]
    curr_na_positions <- na_positions[[s]][[i]]
    
    print("Running original methyLImp...")
    #running methyLImp
    curr_time <- system.time({
      beta_estimated <- methyLImp(curr_data_with_NAs)
    })[3]
    
    perf_orig_nsamples[s, "time_sec"] <- perf_orig_nsamples[s, "time_sec"] + curr_time
    
    #performance evaluation
    curr_perf_orig <- evaluatePerformance(curr_data, beta_estimated, 
                                     curr_na_positions)
    perf_orig_nsamples[s, "RMSE"] <- perf_orig_nsamples[s, "RMSE"] + curr_perf_orig["RMSE"]
    perf_orig_nsamples[s, "MAE"] <- perf_orig_nsamples[s, "MAE"] + curr_perf_orig["MAE"]
    
    save(list = c("perf_orig_nsamples"), file = filename)
    
    gc()
  }
}

perf_orig_nsamples[ , c("time_sec", "RMSE", "MAE")] <- 
  perf_orig_nsamples[ , c("time_sec", "RMSE", "MAE")] / nruns
perf_orig_nsamples <- as.data.frame(perf_orig_nsamples)
perf_orig_nsamples$time_min <- perf_orig_nsamples$time_sec / 60
save(list = c("perf_orig_nsamples"), file = filename)
print(perf_orig_nsamples)

ggplot(perf_orig_nsamples, aes(x = nsamples, y = time_min)) +
  geom_point() +
  geom_line()
