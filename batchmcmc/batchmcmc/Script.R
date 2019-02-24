#Package installation if missing
install.packages("Rcpp")
install.packages("hitandrun")
install.packages("devtools", force= TRUE)
devtools::install_github("Azure/rAzureBatch", force = TRUE)
devtools::install_github("Azure/doAzureParallel@stable", force = TRUE)
devtools::install_github("WagdyIshac/doAzureParallel", force = TRUE)
devtools::install_github("Azure/doAzureParallel@master", force = TRUE)
install.packages("bitops")
install.packages("PerformanceAnalytics")

#update.packages("Rcpp")
#update.packages("hitandrun")
update.packages("devtools")
#update.packages("bitops")

# Load the doAzureParallel library 
library(doAzureParallel)
library("Rcpp")
library("hitandrun")
source("hpcutilTS.R")
library(devtools)

library(rAzureBatch)

# Generating JSON files for credentials to access the Azure Subscription and Cluster details if missing
# generateCredentialsConfig("credentials4.json")
# generateClusterConfig("cluster4.json")
setwd("c:/code/mcmc/batchmcmc/batchmcmc")


#setting Azure credentials
setCredentials("credentials55.json")

makeCluster2 <- makeCluster

#creating the cluster and set parallel work to the cluster
if (length(getClusterList()[, 1]) == 0) {
    clusterHPC77 <- makeCluster(cluster = "clusterHPC.json")
} else {
    clusterHPC77 <- getCluster("mcmchpc777") #if the cluster already exists this command retrieve the cluster 
    #register the parallel methods on the cluster and check the parallel workers
}
registerDoAzureParallel(clusterHPC77)
getDoParWorkers()

#executes the har from teh source file entries
outputFoldername <- "rstudiorun1"
returnURL <- harSetAzureStorage(outputFoldername)
start_p <- Sys.time()
#harfileexec("rhs_Dim10.csv", outputFoldername, have1 = TRUE, fileoutputurl = returnURL)
harfileexec2("data2/file1Test.csv", "data2/file2Test.csv", outputFoldername, fileoutputurl = returnURL)
harfileexecRUNLOCAL("data2/file1Test.csv", "data2/file2Test.csv", outputFoldername, fileoutputurl = returnURL)

end_p <- Sys.time()

as.numeric(end_p - start_p)

getJobResult(outputFoldername + "- job ")

stopCluster(clusterHPC)

x <- simplexConstraints(20)
fhitandrun <- function() {
    return(hitandrun(x, 1E4))
}
results100 <- foreach(i = 1:10) %dopar% { #x <- 10 }
   library('hitandrun')
    fhitandrun()
}

harfileexec2("data/file1Test32.csv", "data/file2Test32.csv")

if (length(getClusterList()[, 1]) == 0) {
    mcmchpcdocker <- makeCluster("clusterHPC - Copy.json")
} else {
    mcmchpcdocker <- getCluster("mcmchpcdocker") #if the cluster already exists this command retrieve the cluster 
    #register the parallel methods on the cluster and check the parallel workers
}
registerDoAzureParallel(mcmchpcdocker)

stopCluster(clusterHPC77)
stopCluster(clusterHPC2)


