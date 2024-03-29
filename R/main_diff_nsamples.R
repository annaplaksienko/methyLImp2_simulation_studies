path <- "ADD_YOUR_PATH_HERE"
setwd(path)

library(parallel)
library(ggplot2)
library(methyLImp2)

#please download the dataset from here
#https://uio-my.sharepoint.com/:u:/g/personal/annapla_uio_no/Ec0RVBJ3HBtKrh316y54DwgBgZq9IumepY0sH9eEvkqctg?e=4NYcpl
#and add into your folder
#load("68_samples.Rdata")

filename_perf <- "perf_nsamples.Rdata"

samp_size_vec <- c(9, 17, 34, 51)

#generate NAs
#print("Generating artificial NAs...")
#lambda_vec <- c(1, 2.5, 5, 7.5)
#nruns <- 5
#beta_subsampled <- beta_with_nas <- na_positions <- 
#  vector(mode = "list", length = length(samp_size_vec))
#names(beta_subsampled) <- names(beta_with_nas) <- names(na_positions) <- 
#  paste0(samp_size_vec, "_samples")
#for (s in 1:length(samp_size_vec)) {
#  beta_with_nas[[s]] <- na_positions[[s]] <- vector(mode = "list", 
#                                                    length = nruns)
#  names(beta_with_nas[[s]]) <- names(na_positions[[s]]) <- 
#    paste0("Run", 1:nruns)
#  curr_samp_size <- samp_size_vec[s]
#  curr_lambda <- lambda_vec[s]
  #subset samples
#  samples <- sample(1:nsamples, size = curr_samp_size)
#  beta_subsampled[[s]] <- beta[samples, ]
  
  #generate NAs
#  for (i in 1:nruns) {
#    res <- generateMissingData(beta_subsampled[[s]], lambda = curr_lambda)
#    beta_with_nas[[s]][[i]] <- res$beta_with_nas
#    na_positions[[s]][[i]] <- res$na_positions
#  }
#}
#remove(res)
#save(list = c("beta", "beta_subsampled", "beta_with_nas", "na_positions"), 
#     file = "beta_for_nsamples.Rdata")

#I already did the generation so I just load the file
#load already subsampled data with generated NAs
load("beta_for_nsamples.Rdata")

nsamples <- dim(beta)[1]
nprobes <- dim(beta)[2]

nruns <- 5

perf_nsamples <- matrix(0, nrow = length(samp_size_vec) * nruns, ncol = 6)
perf_nsamples <- as.data.frame(perf_nsamples)
colnames(perf_nsamples) <- c("nsamples", "run", 
                             "time_sec", "time_min", 
                             "RMSE", "MAE")
perf_nsamples[, "nsamples"] <- rep(samp_size_vec, each = nruns)
perf_nsamples[, "run"] <- paste("Run", rep(c(1:5), length(samp_size_vec)))

ind <- 1
for (s in 1:length(samp_size_vec)) {
  timestamp()
  curr_samp_size <- samp_size_vec[s]
  print(paste("Computing with", curr_samp_size, "samples..."))
  
  curr_data <- beta_subsampled[[s]]
  beta_imputed[[s]] <- vector(mode = "list", length = nruns)

  for (i in 1:nruns) {
    timestamp()
    print(paste0("Run ", i))
    
    curr_data_with_NAs <- beta_with_nas[[s]][[i]]
    curr_na_positions <- na_positions[[s]][[i]]
    
    print("Running methyLImp2...")
    #running methyLImp
    curr_time <- system.time({
      beta_estimated <- methyLImp2(curr_data_with_NAs, type = "EPIC")
    })[3]

    perf_nsamples[ind, "time_sec"] <- curr_time
    
    #performance evaluation
    curr_perf <- evaluatePerformance(curr_data, beta_estimated, 
                                     curr_na_positions)
    perf_nsamples[ind, "RMSE"] <- curr_perf["RMSE"]
    perf_nsamples[ind, "MAE"] <- curr_perf["MAE"]
    
    ind <- ind + 1
    
    save(list = c("perf_nsamples"), file = filename_perf)

    gc()
  }
}

perf_nsamples_mean <- perf_nsamples %>%
  group_by(nsamples) %>%
  summarize(across(time_sec:MAE, mean))
perf_nsamples_sd <- perf_nsamples %>%
  group_by(nsamples) %>%
  summarize(across(time_sec:MAE, sd))

save(list = c("perf_nsamples",
              "perf_nsamples_mean", "perf_nsamples_sd"), 
     file = filename_perf)

