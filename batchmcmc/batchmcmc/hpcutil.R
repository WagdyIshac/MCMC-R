

harfileexec <- function(filename, outputFoldername, have1 = FALSE, fileoutputpatter = "output-") {
    csvfile <- as.matrix(read.csv(file = filename, header = FALSE, sep = ","))
    colnames(csvfile) <- NULL
    if (!have1) {
        rhsmatrix <- cbind(1, csvfile)
    } else { rhsmatrix <- csvfile }
    iterations <- length(rhsmatrix[, 1])
    width <- length(rhsmatrix[1,]) - 1

    returnURL <- harSetAzureStorage(outputFoldername)

    output <- createOutputFile(paste0(fileoutputpatter, "*.csv"), returnURL)
    opt <- list(job = paste0(outputFoldername, '-job'), wait = FALSE, outputFiles = list(output))
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
    x <- simplexConstraints(24)

    #running a small sample
    start_p <- Sys.time()
    results100 <- foreach::foreach(i = 1:100, .packages = 'hitandrun') %dopar% { hitandrun(x, 1E4) }
    end_p <- Sys.time()
    return(results100)
}