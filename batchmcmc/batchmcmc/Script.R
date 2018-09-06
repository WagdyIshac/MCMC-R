
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

# Generating JSON files for credentials to access the Azure Subscription and Cluster details
generateCredentialsConfig("credentials.json")
generateClusterConfig("cluster2.json")

setCredentials("credentials.json")
setwd("c:/code/mcmc/batchmcmc/batchmcmc")

#creating the cluster
clusterHPC <- makeCluster("clusterHPC.json")

#if the cluster already created this command retrieve the cluster
clusterHPC <- getCluster("mcmchpc6")

#register the parallel methods on the cluster and check the parallel workers
registerDoAzureParallel(clusterHPC)
getDoParWorkers()

#preparing the matirx and running the function
x <- simplexConstraints(24)
fhitandrun <- function() {
    return(hitandrun(x, 1E4))
}

#running a small sample
start_p <- Sys.time()
results100 <- foreach::foreach(i = 1:100, .packages = 'hitandrun') %dopar% { fhitandrun() }
end_p <- Sys.time()

#configre the storage to sump the files
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

# Pushing output files by setting the account and foler (container)
storageAccount <- "adiarmcmc"
outputFolder <- "output11"

storageClient$containerOperations$createContainer(outputFolder)
writeToken <- storageClient$generateSasToken("w", "c", outputFolder)
containerUrl <- rAzureBatch::createBlobUrl(storageAccount = storageCredentials$name,
                                           containerName = outputFolder,
                                           sasToken = writeToken)

#setting the files pattern
output <- createOutputFile("output-*.csv", containerUrl)

#setting the options for the job_id, files pattern and no to wait on interactive so submit the Job and not to wait
opt <- list(job = 'mcmc-50', wait = FALSE, outputFiles = list(output))

#loop and dump the data
foreach(i = 1:16, .packages = 'hitandrun', .options.azure = opt) %dopar% {
    r <- hitandrun(x, 1E4)
    write.csv(r, paste0("output-", i, ".csv"))
}

getJobResult("mcmc-60")


harfileexec("rhs_Dim40.csv", have1 = TRUE)

harfileexec <- function(filename, have1 = FALSE, fileoutputpatter = "output-") {
    csvfile <- as.matrix(read.csv(file = filename, header = FALSE, sep = ","))
    colnames(csvfile) <- NULL
    if (!have1) {
        rhsmatrix <- cbind(1, csvfile)
    } else { rhsmatrix <- csvfile }
    iterations <- length(rhsmatrix[, 1])
    width <- length(rhsmatrix[1,]) - 1

    output <- createOutputFile(paste0(fileoutputpatter,"*.csv"), containerUrl)
    opt <- list(job = 'mcmc-60', wait = FALSE, outputFiles = list(output))
    foreach(i = 1:16, .packages = 'hitandrun', .options.azure = opt) %dopar% {
        y <- simplexConstraints(width)
        x <- simplexConstraints(width / 2)
        m <- rbind(x$constr, x$constr)
        ml <- m[-(width / 2 + 2),]
        y$constr <- ml
        y$rhs <- rhsmatrix[i,]
        r <- hitandrun(y, 1E4)
        write.csv(r, paste0(fileoutputpatter, i, ".csv"))
        i
    }
}



