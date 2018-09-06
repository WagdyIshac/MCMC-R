#Package installation if missing
install.packages("Rcpp")
install.packages("hitandrun")
install.packages("devtools")
devtools::install_github("Azure/rAzureBatch")
devtools::install_github("Azure/doAzureParallel")
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

#creating the cluster
if (length(getClusterList()[,1]) ==0) {
    clusterHPC <- makeCluster("clusterHPC.json")
} else {
    clusterHPC <- getCluster("mcmchpc6") #if the cluster already exists this command retrieve the cluster 
    #register the parallel methods on the cluster and check the parallel workers
    registerDoAzureParallel(clusterHPC)
    getDoParWorkers()
}

#executes the har from teh source file entries
harfileexec("rhs_Dim20.csv", "test-out2", have1 = TRUE)

getJobResult("test-out2-job")

stopCluster(clusterHPC)

