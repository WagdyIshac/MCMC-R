
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
setwd("c:/code/mcmc/batchmcmc/batchmcmc")

clusterHPC <- makeCluster("clusterHPC.json")
clusterHPC <-getCluster("mcmchpc")

registerDoAzureParallel(clusterHPC)
getDoParWorkers()

x <- simplexConstraints(2)
fhitandrun <- function() {
    return(hitandrun(x, 1E4))
}

start_p <- Sys.time()
results100 <- foreach::foreach(i = 1:64, .packages = 'hitandrun') %dopar% { fhitandrun() }
end_p <- Sys.time()

config <- rjson::fromJSON(file = paste0("credentials.json"))

storageCredentials <- rAzureBatch::SharedKeyCredentials$new(
  name = config$sharedKey$storageAccount$name,
  key = config$sharedKey$storageAccount$key
)

storageAccountName <- storageCredentials$name

storageClient <- rAzureBatch::StorageServiceClient$new(
  authentication = storageCredentials,
  url = sprintf("https://%s.blob.%s",
               storageCredentials$name,
               config$sharedKey$storageAccount$endpointSuffix
               )
)

# Pushing output files
storageAccount <- "adiarmcmc"
outputFolder <- "simoutputs"

storageClient$containerOperations$createContainer(outputFolder)
writeToken <- storageClient$generateSasToken("w", "c", outputFolder)
containerUrl <- rAzureBatch::createBlobUrl(storageAccount = storageAccount,
                                           containerName = outputFolder,
                                           sasToken = writeToken)

output <- createOutputFile("result*.csv", containerUrl)

opt <- list(job = 'mcmc-18', wait = FALSE, outputFiles = list(output))
foreach(i = 1:4, .packages = 'hitandrun', .options.azure = opt) %dopar% {
    #f <- cat("output", "5", sep = "")
    #fileName <- cat(f, ".csv",sep = "")
    #file.create(fileName)
    #fileConn <- file(fileName)
    r <- hitandrun(x, 1E4)
    write.csv(r, paste0("result",i,".csv"))
}
getJobResult("mcmc-15")


