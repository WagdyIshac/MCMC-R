
install.packages("hitandrun")




# Install the devtools package  
install.packages("devtools")

# Install rAzureBatch package
devtools::install_github("Azure/rAzureBatch")

# Install the doAzureParallel package 
devtools::install_github("Azure/doAzureParallel")

# Load the doAzureParallel library 
library(doAzureParallel)

library("hitandrun")

generateCredentialsConfig("credentials.json")
generateClusterConfig("cluster2.json")

setCredentials("credentials.json")

clusterHPC <- makeCluster("clusterHPC.json")
clusterHPC <-getCluster("mcmchpc")

registerDoAzureParallel(clusterHPC)
getDoParWorkers()

x <- simplexConstraints(40)
fhitandrun <- function() {
    return(hitandrun(x, 1E4))
}

start_p <- Sys.time()
results100 <- foreach::foreach(i = 1:100, .packages = 'hitandrun') %dopar% { fhitandrun() }
end_p <- Sys.time()

write.csv(results100,"results100.csv")

