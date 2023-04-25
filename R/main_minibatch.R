path <- "SET_PATH_HERE"
setwd(path)

library(methyLImp2)
library(ggplot2)

#please download the dataset from here
#https://uio-my.sharepoint.com/:u:/g/personal/annapla_uio_no/ERIX6SObMspBoUKSoj6xKlQByKnnpdn2_qyRTBZdN_YCsA?e=gdwHoQ
#and add it to your folder
#load("456_samples.Rdata")
#nsamples <- dim(beta)[1]
#nprobes <- dim(beta)[2]

filename <- "perf_minibatch.Rdata"

#generate NAs
#print("Generating artificial NAs...")
nruns <- 3
#lambda <- 30
#beta_with_nas <- na_positions <- vector(mode = "list", length = nruns)
#for (i in 1:nruns) {
#  res <- generateMissingData(beta, lambda = lambda)
#  beta_with_nas[[i]] <- res$beta_with_nas
#  na_positions[[i]] <- res$na_positions
#}
#save(list = c("beta", "beta_with_nas", "na_positions"), 
#     file = "beta_for_minibatch.Rdata")
load("beta_for_minibatch.Rdata")

frac_vec <- c(0.1, 0.2, 0.3)
rep_vec <- c(1, 2, 3)
perf_minibatch <- matrix(0, nrow = length(frac_vec) * length(rep_vec), ncol = 6)
colnames(perf_minibatch) <- c("frac", "rep", "time_sec", "time_min", "RMSE", "MAE")
perf_minibatch[, "frac"] <- rep(frac_vec, each = length(rep_vec))
perf_minibatch[, "rep"] <- rep(rep_vec, length(frac_vec))

print("MINIBATCH")
for (i in 1:nruns) {
  timestamp()
  print(paste0("Run ", i))
  
  curr_data_with_NAs <- beta_with_nas[[i]]
  curr_na_positions <- na_positions[[i]]
  
  ind <- 1
  
  for (s in 1:length(frac_vec)) {
    timestamp()
    curr_frac <- frac_vec[s]
    print(paste0("Computing with ", curr_frac * 100, "% of samples..."))
    
    for (l in 1:length(rep_vec)) {
      curr_rep <- rep_vec[l]
      print(paste("Repeating calculations", curr_rep, "time(s)..."))
      
      curr_time <- system.time({
        beta_estimated <- methyLImp2(curr_data_with_NAs, type = "EPIC",
                                     ncores = 9,
                                     minibatch_frac = curr_frac,
                                     minibatch_reps = curr_rep)
      })[3]
      
      perf_minibatch[ind, "time_sec"] <- perf_minibatch[ind, "time_sec"] + curr_time
      
      #performance evaluation
      curr_perf_minibatch <- evaluatePerformance(beta, beta_estimated, 
                                                 curr_na_positions)
      perf_minibatch[ind, "RMSE"] <- perf_minibatch[ind, "RMSE"] + curr_perf_minibatch["RMSE"]
      perf_minibatch[ind, "MAE"] <- perf_minibatch[ind, "MAE"] + curr_perf_minibatch["MAE"]
      
      ind <- ind + 1
    }
  }
  
  save(list = c("perf_minibatch", "i"), file = filename)
  gc()
}

perf_minibatch[ , c("time_sec", "RMSE", "MAE")] <- 
  perf_minibatch[ , c("time_sec", "RMSE", "MAE")] / nruns
perf_minibatch <- as.data.frame(perf_minibatch)
perf_minibatch$time_min <- perf_minibatch$time_sec / 60
save(list = c("perf_minibatch"), file = filename)
print(perf_minibatch)


perf_full <- matrix(0, nrow = nruns, ncol = 6)
colnames(perf_full) <- c("frac", "rep", "time_sec", "time_min", "RMSE", "MAE")
perf_full[, "frac"] <- perf_full[, "rep"] <- rep(1, nruns)

print("FULL dataset")
for (i in 1:nruns) {
  timestamp()
  print(paste0("Run ", i))
  
  curr_data_with_NAs <- beta_with_nas[[i]]
  curr_na_positions <- na_positions[[i]]
  
  curr_time <- system.time({
    beta_estimated <- methyLImp2(curr_data_with_NAs, type = "EPIC",
                                 ncores = 9)
  })[3]
  
  perf_full[i, "time_sec"] <- curr_time
  
  #perf_fullormance evaluation
  curr_perf_full <- evaluatePerformance(beta, beta_estimated, 
                                        curr_na_positions)
  perf_full[i, "RMSE"] <- curr_perf_full["RMSE"]
  perf_full[i, "MAE"] <- curr_perf_full["MAE"]
  
  save(list = c("perf_full", "i"), file = "perf_minibatch_full.Rdata")
  gc()

}
perf_full$time_min <- perf_full$time_sec / 60
perf_full$time_hours <- perf_full$time_min / 60
perf_full_aver <- colMeans(perf_full)
save(list = c("perf_full", "perf_full_aver"), 
     file = "perf_minibatch_full.Rdata")

perf_minibatch$time_hours <- perf_minibatch$time_min / 60
perf_minibatch$frac <- factor(perf_minibatch$frac, 
                              levels = c(0.1, 0.2, 0.3))
#perf$rep <- as.numeric(perf$rep)


dat_text1 <- data.frame(
  label = c("no mini-batch, full dataset"),
  x   = c(2),
  y   = c(0.0275),
  size = c(20)
)

ggplot(perf_minibatch, aes(x = rep, y = RMSE, fill = frac)) +
  geom_col(position = "dodge") +
  geom_hline(yintercept = perf_full_aver["RMSE"]) +
  xlab("Number of mini-batch repetitions") + 
  ylab("Value of root mean square error (RMSE)") +
  scale_fill_discrete("% of samples\nin the mini-batch",
                      labels = c("10%", "20%", "30%")) +
  geom_text(data = dat_text1,
            mapping = aes(x = x, y = y, label = label,
                          fill = NULL, size = size)) +
  guides(size = "none") +
  theme_light(base_size = 16)

dat_text2 <- data.frame(
  label = c("no mini-batch, full dataset"),
  x   = c(2),
  y   = c(30),
  size = c(20)
)

ggplot(perf_minibatch, aes(x = rep, y = time_hours, col = frac)) +
  geom_point(size = 2) +
  geom_line(linewidth = 1) +
  geom_hline(yintercept = perf_full_aver["time_hours"]) +
  scale_x_continuous(breaks = seq(0, 3, by = 1)) +
  scale_y_continuous(breaks = seq(0, 30, by = 5)) +
  xlab("Number of mini-batch repetitions") + 
  ylab("Time in hours") +
  geom_text(data = dat_text2,
            mapping = aes(x = x, y = y, label = label,
                          color = NULL, size = size)) +
  guides(size = "none") +
  theme_light(base_size = 16)


