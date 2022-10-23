#Package installation if missing
install.packages("Rcpp")
install.packages("hitandrun")
install.packages("devtools")
devtools::install_github("Azure/rAzureBatch")
devtools::install_github("Azure/doAzureParallel")
install.packages("bitops")
install.packages("PerformanceAnalytics")

setwd("c:/code/mcmc/batchmcmc/batchmcmc")
# Load the doAzureParallel library 
library(doAzureParallel)
library("Rcpp")
library("hitandrun")
source("hpcutilTS.R")
library(devtools)

#library(rAzureBatch)

# Generating JSON files for credentials to access the Azure Subscription and Cluster details if missing
# generateCredentialsConfig("credentials4.json")
# generateClusterConfig("cluster4.json")


#setting Azure credentials
setCredentials("credentials55.json")


#creating the cluster and set parallel work to the cluster
if (length(getClusterList()[, 1]) == 0) {
    liteClusterDemo <- makeCluster(cluster = "clusterHPC.json")
} else {
    liteClusterDemo <- getCluster("mcmcdemo") #if the cluster already exists this command retrieve the cluster 
}

registerDoAzureParallel(liteClusterDemo)
getDoParWorkers()

#executes the har from teh source file entries
outputFoldername <- "readydemo"
returnURL <- harSetAzureStorage(outputFoldername)

###Load files################################################
path = "Test27Feb2019/"
out.file <- ""
file1 <- dir(path, pattern = "file1{1}",full.names = FALSE)
file2 <- dir(path, pattern = "file2{1}", full.names = FALSE)
file3 <- dir(path, pattern = "file3{1}", full.names = FALSE)
idFiles <- dir(path, pattern = "idFile{1}", full.names = FALSE)


for (i in 1:length(file1)) {

    file <- as.matrix(read.csv(file = paste0(path, file1[i]), header = FALSE, sep = ","))
    if (file[1, 1] == 0)
        {
        #outputFoldername <- paste0(gsub(".csv","", gsub("_","",file1[i])), "-20190228")
        #returnURL <- harSetAzureStorage(outputFoldername)
        harfileexec2(paste0(path, file1[i]), NULL, paste0(path, file3[i]), paste0(path, idFiles[i]), 0, outputFoldername, fileoutputurl = returnURL)

    } else {
        #outputFoldername <- paste0(gsub(".csv", "", gsub("_", "", file1[i])), "-20190228")
        #returnURL <- harSetAzureStorage(outputFoldername)
        harfileexec2(paste0(path, file1[i]), paste0(path, file2[i]), paste0(path, file3[i]), paste0(path, idFiles[i]), 1, outputFoldername, fileoutputurl = returnURL )

    }
}

stopCluster(liteClusterDemo)
