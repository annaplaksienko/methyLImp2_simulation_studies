# methyLImp2 simulation studies
This repository contains all the code that I have used for the simulation studies of the _methyLImp2_ paper. However, if something is missing, please don't hesitate to contact me for clarifications.

## Data
I have used two datasets for the similation: both EPIC array, one with 68 samples (GSE19905) and another with 456 samples (GSE158063). I have added .R files for how I have downloaded the data from GEO database and filtered some samples and then SNPs and sex chromosomes. If you want to skip that step, you can download .Rdata objects from [here for 68 samples](https://uio-my.sharepoint.com/:u:/g/personal/annapla_uio_no/ESgSg-uSDJJNnXUSJ8hB3vIBv2cSZROFXp6WQUelomjpYw?e=IjMyT7) and [here for 456 samples dataset](https://uio-my.sharepoint.com/:u:/g/personal/annapla_uio_no/ERIX6SObMspBoUKSoj6xKlQByKnnpdn2_qyRTBZdN_YCsA?e=gdwHoQ).

Same way, I have added .R files describing how to handled 450K and EPIC annotation for the package. Seem them also for links for original files on Illumina website. .Rdata annotation objects are added here and to the package.

## Code

Here are the files used for simulation:

1. _main_diff_nsamples.R_ first generates articifical NAs for 9, 17, 34 and 51 samples (subsetted from the 68 sampels dataset) and then runs _methyLImp2_, measuring running time and performance.

2. _main_diff_nsamples_ORIG.R_ measures the running time and performance for original _methyLImp_ method (not that it doesn't generate artifical NAs, you should use the code from the previous file or, if you are going for fair comparison, the same data you've already generated from the previous file).

3. _main_diff_ncores.R_ measures running time for 68 samples on different number of cores used with parallel computing.

4. _main_minibatch.R_ first generates articifical NAs for the 456 samples dataset and the runs _methyLImp2_ with different mini-batch settings, varying a fraction of samples and number of repetitions the algorithm does. It also runs _methyLImp2_ on the full dataset. 


