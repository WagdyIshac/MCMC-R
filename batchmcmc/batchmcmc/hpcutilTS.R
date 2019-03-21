



harfileexec2 <- function(filename, extraAmmendment, anchor, idfile, ammendedfileExists, fileoutputpatter = "output-", fileoutputurl) {
    csvfile <- as.matrix(read.csv(file = filename, header = FALSE, sep = ","))
    if (ammendedfileExists == 1) {
        extraAmmendment <- as.matrix(read.csv(file = extraAmmendment, header = FALSE, sep = ","))
    }
    #csvfile <- as.matrix(read.csv(file = "Test24Feb2019/file1_178_13.csv", header = FALSE, sep = ","))
    #extraAmmendment <- as.matrix(read.csv(file = "Test24Feb2019/file2_178_13.csv", header = FALSE, sep = ","))
    #anchor <- as.matrix(read.csv(file = "Test24Feb2019/file3_178_13.csv", header = FALSE, sep = ","))
    anchor <- as.matrix(read.csv(file = anchor, header = FALSE, sep = ","))
    idfile <- as.matrix(read.csv(file = idfile, header = FALSE, sep = ","))

    funds <- as.matrix(read.csv(file = "Test27Feb2019/dataFile1Test.csv", header = FALSE, sep = ","))
    refdata <- as.matrix(read.csv(file = "Test27Feb2019/dataFile2Test.csv", header = FALSE, sep = ","))

    print("loading finished...")

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


    print("initiation finished...")

    output <- createOutputFile(paste0(fileoutputpatter, "*.csv"), fileoutputurl)
    opt <- list(wait = TRUE, outputFiles = list(output), enableCloudCombine = FALSE, setAutoDeleteJob = FALSE)
    foreach::foreach(i = i:20, .options.azure = opt) %dopar% {
        library('hitandrun')
        library('PerformanceAnalytics')
        #foreach::foreach(i = 1:iterations) %do% {
        dim <- (length(rhsmatrix[1,]) - 2) / 2
        lb <- rhsmatrix[i, (dim + 3):length(rhsmatrix[1,])]
        lb <- lb * -1
        rhsmatrix[i, (dim + 3):length(rhsmatrix[1,])] <- lb
        y$rhs <- rhsmatrix[i, 2:length(rhsmatrix[1,])]

        r <- hitandrun(y, 1E2, eliminate = FALSE)
        rr <- shakeandbake(y, 1E2, eliminate = FALSE)

        otpt <- rbind(r, rr)
        ammended <- NULL
        if (ammendedfileExists == 1) {
            newM = matrix(rep(extraAmmendment[i, 1:rhsmatrix[i, 1]], 200),
         ncol = rhsmatrix[i, 1],
         byrow = 200)
            ammended <- cbind(otpt, newM)
        } else { ammended <- otpt }

        theid = idfile[i, 1]


        write.csv(cbind(theid, round(ammended, 5)), paste0(fileoutputpatter, "-harsab\\", theid, ".csv"))
        #write.csv(round(ammended, 5), paste0("dataout/testcombine2", "-harsab-", i, ".csv"))
        #i
        #####################################################################################
        ############ Times Series Generation ################################################
        ammendedT = t(ammended)

        #backward
        startpos = anchor[i, 1] - 35
        len <- length(ammended[1,])
        pastinterval <- funds[startpos:anchor[i, 1],]
        pastI <- pastinterval[, anchor[i, 2:(len + 1)]]
        timeseries <- pastI %*% ammendedT
        ###########################fix anchor point for late times - Done
        ###########################include IDs
        ###########################check for the zero for no ammendment files - Done
        ###########################load data files in memory

        refdatabackward <- refdata[(anchor[i] - 35):(anchor[i]),]

        BackwardAnn <- matrix(, nrow = 200, ncol = 3)

        lmBackward12 <- matrix(, nrow = 200, ncol = 7)
        lmBackward1 <- matrix(, nrow = 200, ncol = 5)
        lmBackward2 <- matrix(, nrow = 200, ncol = 5)

        for (bb in 1:length(timeseries[1, ])) {
            BackwardAnn[bb, 1] <- sd(timeseries[, bb]) * sqrt(12)
            BackwardAnn[bb, 2] <- Return.annualized(timeseries[, bb], scale = 12)
            BackwardAnn[bb, 3] <- maxDrawdown(timeseries[, bb])

            ResBackward12 = lm(timeseries[, bb] ~ refdatabackward[, 1] + refdatabackward[, 2])
            ResBackward1 = lm(timeseries[, bb] ~ refdatabackward[, 1])
            ResBackward2 = lm(timeseries[, bb] ~ refdatabackward[, 2])

            lmBackward12[bb, 2:4] <- ResBackward12$coefficients
            lmBackward12[bb, 1] <- summary(ResBackward12)$adj.r.squared
            lmBackward12[bb, 5:7] <- summary(ResBackward12)$coefficients[, 4]

            lmBackward1[bb, 2:3] <- ResBackward1$coefficients
            lmBackward1[bb, 1] <- summary(ResBackward1)$adj.r.squared
            lmBackward1[bb, 4:5] <- summary(ResBackward1)$coefficients[, 4]

            lmBackward2[bb, 2:3] <- ResBackward2$coefficients
            lmBackward2[bb, 1] <- summary(ResBackward2)$adj.r.squared
            lmBackward2[bb, 4:5] <- summary(ResBackward2)$coefficients[, 4]


        }


        write.csv(cbind(theid, timeseries), paste0(fileoutputpatter, "-timeseries-backward", theid, ".csv"))
        write.csv(cbind(theid, BackwardAnn), paste0(fileoutputpatter, "-timeseries-Backward-Annual", theid, ".csv"))

        write.csv(cbind(theid, lmBackward12), paste0(fileoutputpatter, "-timeseries-Backward-lmBackward12", theid, ".csv"))
        write.csv(cbind(theid, lmBackward1), paste0(fileoutputpatter, "-timeseries-Backward-lmBackward1", theid, ".csv"))
        write.csv(cbind(theid, lmBackward2), paste0(fileoutputpatter, "-timeseries-Backward-lmBackward2", theid, ".csv"))


        #forward
        endpos <- (anchor[i, 1] + 36)
        forwardLength <- 36
        if ((anchor[i, 1] + 36) > length(funds[, i]))
            {
            endpos <- length(funds[, i])
            forwardLength <- (endpos - (anchor[i, 1]))
        }
        forwardInterval <- funds[(anchor[i, 1] + 1):endpos,]
        forwardI <- forwardInterval[, anchor[i, 2:(len + 1)]]
        forwardI <- forwardI + 1
        allforward = matrix(rep(1, forwardLength),
         ncol = 1,
         byrow = forwardLength)

        allcov <- double(0)
        allAnn <- double(0)

        refdataforward <- refdata[(anchor[i] + 1):endpos,]


        #ForwardCov <- matrix(, nrow = 200, ncol = length(refdata[1,]))
        ForwardAnn <- matrix(, nrow = 200, ncol = 3)
        lmForward12 <- matrix(, nrow = 200, ncol = 7)
        lmForward1 <- matrix(, nrow = 200, ncol = 5)
        lmForward2 <- matrix(, nrow = 200, ncol = 5)

        for (kk in 1:length(ammended[, 1])) {
            #kk <- 1
            forwardMain <- rbind(ammended[kk,], forwardI)
            forwardMain <- apply(forwardMain, 2, cumprod)
            forwardRow <- rowSums(forwardMain)
            forwarddiffs <- (forwardRow[2:(forwardLength + 1)] / forwardRow[1:forwardLength]) - 1
            allforward <- cbind(allforward, forwarddiffs)


            #}
            ################ FIX THE LENGTH
            ###Calcs
            allAnn[1] <- sd(forwarddiffs) * sqrt(12)
            allAnn[2] <- Return.annualized(forwarddiffs, scale = 12)
            allAnn[3] <- maxDrawdown(forwarddiffs)

            ForwardAnn[kk,] <- allAnn



            #for (covi in 1:length(refdata[1, ])) {
            #covVal = cov(forwarddiffs, refdataforward[,covi])
            #allcov[covi] <- covVal
            #}
            #ForwardCov[kk,] <- allcov

            ResForward12 = lm(forwarddiffs ~ refdataforward[, 1] + refdataforward[, 2])
            ResForward1 = lm(forwarddiffs ~ refdataforward[, 1])
            ResForward2 = lm(forwarddiffs ~ refdataforward[, 2])

            lmForward12[kk, 2:4] <- ResForward12$coefficients
            lmForward12[kk, 1] <- summary(ResForward12)$adj.r.squared
            lmForward12[kk, 5:7] <- summary(ResForward12)$coefficients[, 4]

            lmForward1[kk, 2:3] <- ResForward1$coefficients
            lmForward1[kk, 1] <- summary(ResForward1)$adj.r.squared
            lmForward1[kk, 4:5] <- summary(ResForward1)$coefficients[, 4]

            lmForward2[kk, 2:3] <- ResForward2$coefficients
            lmForward2[kk, 1] <- summary(ResForward2)$adj.r.squared
            lmForward2[kk, 4:5] <- summary(ResForward2)$coefficients[, 4]


        }


        write.csv(cbind(theid, allforward[, 2:201]), paste0(fileoutputpatter, "-timeseries-forward", theid, ".csv"))
        write.csv(cbind(theid, ForwardAnn), paste0(fileoutputpatter, "-timeseries-forward-Annual", theid, ".csv"))
        # write.csv(ForwardCov, paste0(fileoutputpatter, "-timeseries-forward-Covarience-", i, ".csv"))

        write.csv(cbind(theid, lmForward12), paste0(fileoutputpatter, "-timeseries-forward-lmForward12", theid, ".csv"))
        write.csv(cbind(theid, lmForward1), paste0(fileoutputpatter, "-timeseries-forward-lmForward1", theid, ".csv"))
        write.csv(cbind(theid, lmForward2), paste0(fileoutputpatter, "-timeseries-forward-lmForward2", theid, ".csv"))

        ###################################################################################
        ################## Time series  calculations ###############################
        return(NULL)
    }
}

harfileexecRUNLOCAL <- function(filename, extraAmmendment, fileoutputpatter = "output-", fileoutputurl) {
    csvfile <- as.matrix(read.csv(file = "data2/file1Test.csv", header = FALSE, sep = ","))
    extraAmmendment <- as.matrix(read.csv(file = "data2/file2Test.csv", header = FALSE, sep = ","))
    funds <- as.matrix(read.csv(file = "data2/dataFile1Test.csv", header = FALSE, sep = ","))
    anchor <- as.matrix(read.csv(file = "data2/file3Test.csv", header = FALSE, sep = ","))
    refdata <- as.matrix(read.csv(file = "data2/dataFile2Test.csv", header = FALSE, sep = ","))
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


    #output <- createOutputFile(paste0(fileoutputpatter, "*.csv"), fileoutputurl)
    #opt <- list(job = paste0(, '-job'), wait = TRUE, outputFiles = list(output), merge = FALSE)
    #foreach::foreach(i = 1:iterations, .options.azure = opt) %do% {
    #library('hitandrun')
    #library('PerformanceAnalytics')
    foreach::foreach(i = 1:iterations) %do% {
        i = 201
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
        #write.csv(round(ammended, 5), paste0(fileoutputpatter, "-harsab-", i, ".csv"))
        write.csv(round(ammended, 5), paste0("dataout2/testcombine2", "-harsab-", i, ".csv"))
        #i
        #####################################################################################
        ############ Times Series Generation ################################################
        ammendedT = t(ammended)

        #backward
        startpos = anchor[i, 1] - 35
        len <- length(ammended[1,])
        pastinterval <- funds[startpos:anchor[i, 1],]
        pastI <- pastinterval[, anchor[i, 2:(len + 1)]]
        timeseries <- pastI %*% ammendedT

        write.csv(timeseries, paste0("dataout2/testcombine2", "-timeseries-backward-", i, ".csv"))
        #forward
        forwardInterval <- funds[anchor[i, 1]:(anchor[i, 1] + 35),]
        forwardI <- forwardInterval[, anchor[i, 2:(len + 1)]]
        forwardI <- forwardI + 1
        allforward = matrix(rep(1, 36),
         ncol = 1,
         byrow = 36)

        allcov <- double(0)
        allAnn <- double(0)

        ForwardCov <- matrix(, nrow = 200, ncol = length(refdata[1,]))
        ForwardAnn <- matrix(, nrow = 200, ncol = 3)
        lmForward12 <- matrix(, nrow = 200, ncol = 7)
        lmForward1 <- matrix(, nrow = 200, ncol = 5)
        lmForward2 <- matrix(, nrow = 200, ncol = 5)

        for (kk in 1:length(ammended[, 1])) {

            #kk <- 1
            forwardMain <- rbind(ammended[kk,], forwardI)
            forwardMain <- apply(forwardMain, 2, cumprod)
            forwardRow <- rowSums(forwardMain)
            forwarddiffs <- (forwardRow[2:36] / forwardRow[1:35]) - 1

            ###Calcs
            allAnn[1] <- sd(forwarddiffs) * sqrt(12)
            allAnn[2] <- Return.annualized(forwarddiffs, scale = 12)
            allAnn[3] <- maxDrawdown(forwarddiffs)

            ForwardAnn[kk,] <- allAnn

            for (covi in 1:length(refdata[1, ])) {
                covVal = cov(forwarddiffs, refdata[anchor[i]:(anchor[i] + 34), covi])
                allcov[covi] <- covVal
            }
            ForwardCov[kk,] <- allcov

            ResForward12 = lm(forwarddiffs ~ refdata[anchor[i]:(anchor[i] + 34), 1] + refdata[anchor[i]:(anchor[i] + 34), 2])
            ResForward1 = lm(forwarddiffs ~ refdata[anchor[i]:(anchor[i] + 34), 1])
            ResForward2 = lm(forwarddiffs ~ refdata[anchor[i]:(anchor[i] + 34), 2])

            lmForward12[kk, 2:4] <- ResForward12$coefficients
            lmForward12[kk, 1] <- summary(ResForward12)$adj.r.squared
            lmForward12[kk, 5:7] <- summary(ResForward12)$coefficients[, 4]

            lmForward1[kk, 2:3] <- ResForward1$coefficients
            lmForward1[kk, 1] <- summary(ResForward1)$adj.r.squared
            lmForward1[kk, 4:5] <- summary(ResForward1)$coefficients[, 4]

            lmForward2[kk, 2:3] <- ResForward2$coefficients
            lmForward2[kk, 1] <- summary(ResForward2)$adj.r.squared
            lmForward2[kk, 4:5] <- summary(ResForward2)$coefficients[, 4]

            allforward <- cbind(allforward, forwarddiffs)
        }
        write.csv(allforward, paste0("dataout2/testcombine2", "-timeseries-forward-", i, ".csv"))
        write.csv(ForwardAnn, paste0("dataout2/testcombine2", "-timeseries-forward-Annual-", i, ".csv"))
        write.csv(ForwardCov, paste0("dataout2/testcombine2", "-timeseries-forward-Covarience-", i, ".csv"))

        write.csv(lmForward12, paste0("dataout2/testcombine2", "-timeseries-forward-lmForward12-", i, ".csv"))
        write.csv(lmForward1, paste0("dataout2/testcombine2", "-timeseries-forward-lmForward1-", i, ".csv"))
        write.csv(lmForward2, paste0("dataout2/testcombine2", "-timeseries-forward-lmForward2-", i, ".csv"))

        ###################################################################################
        ################## Time series  calculations ###############################

    }
}

harSetAzureStorage <- function(foldername) {
    config <- rjson::fromJSON(file = paste0("credentials55.json"))

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

timeseriesgeneration <- function(funds, anchor) {

    ammendedT = t(ammended)

    #backward
    startpos = anchor[1, 1] - 35
    len <- length(ammended[1,])
    pastinterval <- funds[startpos:anchor[1, 1],]
    pastI <- pastinterval[, anchor[1, 2:(len + 1)]]
    pastI[, 9] <- 0
    timeseries <- pastI %*% ammendedT
    length(pastI[1,])
    length(ammendedT[, 1])

    #forward
    forwardInterval <- funds[anchor[1, 1]:(anchor[1, 1] + 35),]
    forwardI <- forwardInterval[, anchor[1, 2:(len + 1)]]
    forwardI <- forwardI + 1
    foreach(kk <- 1:length(ammended[, 1])) %do% {
        kk <- 1
        forwardMain <- rbind(ammended[kk,], forwardI)
        forwardMain <- apply(forwardMain, 2, cumprod)
        forwardRow <- rowSums(forwardMain)
        forwarddiffs <- forwardRow[2:36] / (forwardRow[2:36] - 1)
    }
}