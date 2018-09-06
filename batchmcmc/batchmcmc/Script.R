#Package installation if missing
install.packages("hitandrun")
install.packages("devtools")
devtools::install_github("Azure/rAzureBatch")
devtools::install_github("Azure/doAzureParallel")
install.packages("bitops")

# Load the doAzureParallel library 
library(doAzureParallel)
library("hitandrun")
source("hpcutil.R")


# Generating JSON files for credentials to access the Azure Subscription and Cluster details if missing
# generateCredentialsConfig("credentials.json")
# generateClusterConfig("cluster2.json")
# setwd("c:/code/batchmcmc/batchmcmc")



setCredentials("credentials.json")
#creating the cluster
clusterHPC <- makeCluster("clusterHPC.json")
#if the cluster already created this command retrieve the cluster
clusterHPC <- getCluster("mcmchpc6")

#register the parallel methods on the cluster and check the parallel workers
registerDoAzureParallel(clusterHPC)
getDoParWorkers()

#executes the har from teh source file entries
harfileexec("rhs_Dim20.csv", "test-out2",  have1 = TRUE)

getJobResult("mcmc-60")

