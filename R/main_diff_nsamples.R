path <- "ADD_YOUR_PATH_HERE"
setwd(path)

library(parallel)
library(ggplot2)
library(methyLImp2)

#please download the dataset from here
#https://uio-my.sharepoint.com/:u:/g/personal/annapla_uio_no/EcZCEmgbCnFFl9uIgxnBog8B7kfiFBXR27VSw9EnaDTw0g?e=LZzJH1
#and add into your folder
load("68_samples.Rdata")
nsamples <- dim(beta)[1]
nprobes <- dim(beta)[2]

filename <- "perf_nsamples.Rdata"

samp_size_vec <- c(9, 17, 34, 51)
lambda_vec <- c(1, 2.5, 5, 7.5)
nruns <- 5

perf_nsamples <- matrix(0, nrow = length(samp_size_vec), ncol = 5)
colnames(perf_nsamples) <- c("nsamples", "time_sec", "time_min", "RMSE", "MAE")
perf_nsamples[, 1] <- samp_size_vec

for (s in 1:length(samp_size_vec)) {
  timestamp()
  curr_samp_size <- samp_size_vec[s]
  curr_lambda <- lambda_vec[s]
  print(paste("Computing with", curr_samp_size, "samples..."))

  for (i in 1:nruns) {
    timestamp()
    print(paste0("Run ", i, ". Generating artificial NAs..."))
    
    #subset samples
    samples <- sample(1:nsamples, size = curr_samp_size)
    curr_data <- beta[samples, ]

    #generate NAs
    res <- generateMissingData(curr_data, lambda = curr_lambda)
    curr_data_with_NAs <- res$beta_with_nas
    curr_na_positions <- res$na_positions
    
    print("Running methyLImp2...")
    #running methyLImp
    curr_time <- system.time({
      beta_estimated <- methyLImp2(curr_data_with_NAs, type = "EPIC")
    })[3]
    
    perf_nsamples[s, "time_sec"] <- perf_nsamples[s, "time_sec"] + curr_time
    
    #performance evaluation
    curr_perf <- evaluatePerformance(curr_data, beta_estimated, 
                                     curr_na_positions)
    perf_nsamples[s, "RMSE"] <- perf_nsamples[s, "RMSE"] + curr_perf["RMSE"]
    perf_nsamples[s, "MAE"] <- perf_nsamples[s, "MAE"] + curr_perf["MAE"]
    
    save(list = c("perf_nsamples"), file = filename)
    
    gc()
  }
}

perf_nsamples[ , c("time_sec", "RMSE", "MAE")] <- 
  perf_nsamples[ , c("time_sec", "RMSE", "MAE")] / nruns
perf_nsamples <- as.data.frame(perf_nsamples)
perf_nsamples$time_min <- perf_nsamples$time_sec / 60
save(list = c("perf_nsamples"), file = filename)
print(perf_nsamples)

ggplot(perf_nsamples, aes(x = nsamples, y = time_min)) +
  geom_point() +
  geom_line()
