

harfileexec <- function(filename, outputFoldername, have1 = FALSE, fileoutputpatter = "output-", fileoutputurl, numberofruns) {
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
    opt <- list(job = paste0(outputFoldername, '-job'), wait = TRUE, outputFiles = list(output), merge = FALSE)
    foreach::foreach(i = 1:iterations, .packages = ('hitandrun'), .options.azure = opt) %dopar% {

        y$rhs <- rhsmatrix[i,]
        r <- hitandrun(y, 1E2, eliminate = FALSE)
        rr <- shakeandbake(y, 1E2, eliminate = FALSE)
        otpt <- rbind(r, rr)
        write.csv(round(otpt, 5), paste0(fileoutputpatter, "-harsab-", i, ".csv"))
        i
    }
}

harfileexec2 <- function(filename, extraAmmendment, fileoutputpatter = "output-", fileoutputurl) {
    csvfile <- as.matrix(read.csv(file = filename, header = FALSE, sep = ","))
    extraAmmendment <- as.matrix(read.csv(file = extraAmmendment, header = FALSE, sep = ","))
    #csvfile <- as.matrix(read.csv(file = "data/file1Test32.csv", header = FALSE, sep = ","))
    #extraAmmendment <- as.matrix(read.csv(file = "data/file2Test32.csv", header = FALSE, sep = ","))
    colnames(csvfile) <- NULL
    rhsmatrix <- csvfile
    iterations <- length(rhsmatrix[, 1])
    width <- length(rhsmatrix[1,]) - 2
    y <- simplexConstraints(width)
    x <- simplexConstraints(width / 2)
    m <- rbind(x$constr * -1, x$constr)
    ml <- m[-(width / 2 + 2),]
    ml[1,] <- ml[1,] * -1
    y$constr <- ml


    output <- createOutputFile(paste0(fileoutputpatter, "*.csv"), fileoutputurl)
    opt <- list(job = paste0(outputFoldername, '-job'), wait = TRUE, outputFiles = list(output), merge = FALSE)
    foreach::foreach(i = 1:iterations, .options.azure = opt) %dopar% {
        library('hitandrun')
        #foreach::foreach(i = 1:iterations) %do% {
        dim <- (length(rhsmatrix[1,]) - 2) / 2
        lb <- rhsmatrix[i, (dim + 3):length(rhsmatrix[1,])]
        lb <- lb * -1
        rhsmatrix[i, (dim + 3):length(rhsmatrix[1,])] <- lb
        y$rhs <- rhsmatrix[i, 2:length(rhsmatrix[1,])]


        r <- hitandrun(y, 1E2, eliminate = FALSE)
        rr <- shakeandbake(y, 1E2, eliminate = FALSE)
        otpt <- rbind(r, rr)
        newM = matrix(rep(extraAmmendment[i, 1:rhsmatrix[i, 1]], 200),
         ncol = rhsmatrix[i, 1],
         byrow = 200)
        ammended <- cbind(otpt, newM)
        write.csv(round(ammended, 5), paste0(fileoutputpatter, "-harsab-", i, ".csv"))
        #write.csv(round(ammended, 5), paste0("dataout/testcombine2", "-harsab-", i, ".csv"))


        i
    }
}

harSetAzureStorage <- function(foldername) {
    config <- rjson::fromJSON(file = paste0("credentials.json"))

    storageCredentials <- rAzureBatch::SharedKeyCredentials$new(
  name = config$storageAccount$name,
  key = config$storageAccount$key
    )

    storageAccountName <- storageCredentials$name

    storageClient <- rAzureBatch::StorageServiceClient$new(
  authentication = storageCredentials,
  url = sprintf("https://%s.blob.%s",
               storageCredentials$name,
               config$storageAccount$endpointSuffix
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
    results100 <- foreach::foreach(i = 1:4, .packages = 'hitandrun') %dopar% { hitandrun(x, 1E2) }
    end_p <- Sys.time()
    return(results100)
}

timeseriesgeneration <- function() {
    funds <- as.matrix(read.csv(file = "data/data1.csv", header = FALSE, sep = ","))
    anchor <- as.matrix(read.csv(file = "data/file3Test32.csv", header = FALSE, sep = ","))
    ammendedT = t(ammended)

    #backward
    startpos = anchor[1, 1] - 35
    len <- length(ammended[1,])
    pastinterval <- funds[startpos:anchor[1, 1],]
    pastI <- pastinterval[, anchor[1, 2:(len+1)]]
    timeseries <- pastI %*% ammendedT
    length(pastI[1,])
    length(ammendedT[, 1])

    #forward
    forwardInterval <- funds[anchor[1, 1]:(anchor[1, 1] + 35),]
    forwardI <- forwardInterval[, anchor[1, 2:(len + 1)]]
    forwardI <- forwardI+1
    foreach(kk <- 1:length(ammended[, 1]))
    {
        kk <-1
        forwardMain <- rbind(ammended[kk,], forwardI)
        forwardMain <- apply(forwardMain, 2, cumprod)
        forwardRow <- rowSums(forwardMain)
        forwarddiffs <- forwardRow[2:36] / (forwardRow[2:36]-1)
    }
}