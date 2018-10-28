#Package installation if missing
install.packages("Rcpp")
install.packages("hitandrun")
install.packages("devtools")
devtools::install_github("Azure/rAzureBatch",force=TRUE)
devtools::install_github("Azure/doAzureParallel", force = TRUE)
install.packages("bitops")

# Load the doAzureParallel library 
library(doAzureParallel)
library("Rcpp")
library("hitandrun")
source("hpcutil.R")


# Generating JSON files for credentials to access the Azure Subscription and Cluster details if missing
# generateCredentialsConfig("credentials.json")
# generateClusterConfig("cluster2.json")
# setwd("c:/code/batchmcmc/batchmcmc")


#setting Azure credentials
setCredentials("credentials.json")

#creating the cluster and set parallel work to the cluster
if (length(getClusterList()[,1]) ==0) {
    clusterHPC <- makeCluster("clusterHPC.json")
} else {
    clusterHPC <- getCluster("mcmchpc6") #if the cluster already exists this command retrieve the cluster 
    #register the parallel methods on the cluster and check the parallel workers
}
registerDoAzureParallel(clusterHPC)
getDoParWorkers()

#executes the har from teh source file entries
outputFoldername <- "realrun5-1020-5000-2"
returnURL <- harSetAzureStorage(outputFoldername)
start_p <- Sys.time()
harfileexec("rhs_Dim5.csv", outputFoldername, have1 = TRUE, fileoutputurl = returnURL)
end_p <- Sys.time()
as.numeric(end_p - start_p)

getJobResult(outputFoldername+"- job ")

stopCluster(clusterHPC)

