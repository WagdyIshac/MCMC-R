

harfileexec <- function(filename, outputFoldername, have1 = FALSE, fileoutputpatter = "output-", fileoutputurl) {
    csvfile <- as.matrix(read.csv(file = filename, header = FALSE, sep = ","))
    colnames(csvfile) <- NULL
    if (!have1) {
        rhsmatrix <- cbind(1, csvfile)
    } else { rhsmatrix <- csvfile }
    iterations <- length(rhsmatrix[, 1])
    width <- length(rhsmatrix[1,]) - 1
    y <- simplexConstraints(width)
    x <- simplexConstraints(width / 2)
    m <- rbind(x$constr, x$constr)
    ml <- m[-(width / 2 + 2),]
    y$constr <- ml


    output <- createOutputFile(paste0(fileoutputpatter, "*.csv"), fileoutputurl)
    opt <- list(job = paste0(outputFoldername, '-job'), wait = TRUE, outputFiles = list(output))
    foreach(i = 1:1020, .packages = 'hitandrun', .options.azure = opt) %dopar% {
        y$rhs <- rhsmatrix[i,]
        for(runs in 1:5000) {
            r <- hitandrun(y, 1E2, eliminate = FALSE)
            rr <- shakeandbake(y, 1E2, eliminate = FALSE)
            write.csv(round(r, 5), paste0(fileoutputpatter, "-har-", i, "-run-", runs, ".csv"))
            write.csv(round(rr, 5), paste0(fileoutputpatter, "-sab-", i, "-run-", runs, ".csv"))
        }
        i
    }
}

harSetAzureStorage <- function(foldername) {
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
    outputFolder <- foldername

    storageClient$containerOperations$createContainer(outputFolder)
    writeToken <- storageClient$generateSasToken("w", "c", outputFolder)
    containerUrl <- rAzureBatch::createBlobUrl(storageAccount = storageCredentials$name,
                                           containerName = outputFolder,
                                           sasToken = writeToken)
    return(containerUrl)
}

#preparing the matirx and running the function
harTestFunction <- function() {
    x <- simplexConstraints(10)

    #running a small sample
    start_p <- Sys.time()
    results100 <- foreach::foreach(i = 1:4, .packages = 'hitandrun') %do% { hitandrun(x, 1E2) }
    end_p <- Sys.time()
    return(results100)
}