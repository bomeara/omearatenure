#install.packages('dismo')
library(dismo)
#Good dataresourcekey
good<-c(
674 ,#Arizona state herp collection
675 ,#Arizona state lichen collection
676 ,#Arizona state vascular plant
977 ,#Herps in Alaska
973 ,#birds at UNM
980 ,#mammals at UNM
988 ,#fish at UNM
972 ,#mammals at UNM
985 ,#museum southwestern biology
11617 ,#DMNS birds
7911 ,#kansas entomology
7914 ,#kansas lichen
7915 ,#kansas vascular plants
995 ,#kansas fish
982 ,#kansas herps
13717 ,#ohio state fish
7984 #LSU herbarium
)
#wicked good
wickedgood<-c(
#581 ,#mcz mammals
#580 ,#mcz birds
#579 ,#MCZ fish
#158 ,#antweb
#177 ,#field museum mammals
#8967 ,#NYBG herbarium
#625 ,#ohio state insects
#12031 ,#MCZ herps
1066 #USDA plant db
)

paleoDB<-563 #paleodb


gbif2<-function (genus, species = "", ext = NULL, geo = TRUE, sp = FALSE, 
    removeZeros = TRUE, download = TRUE, getAlt = TRUE, ntries = 720, 
    nrecs = 1000, start = 1, end = NULL, feedback = 3, dataresourcekey=NULL) 
{
    if (!require(XML)) {
        stop("You need to install the XML package to use this function")
    }
    gbifxmlToDataFrame <- function(s) {
        doc = xmlInternalTreeParse(s)
        nodes <- getNodeSet(doc, "//to:TaxonOccurrence")
        if (length(nodes) == 0) 
            return(data.frame())
        varNames <- c("continent", "country", "stateProvince", 
            "county", "locality", "decimalLatitude", "decimalLongitude", 
            "coordinateUncertaintyInMeters", "maximumElevationInMeters", 
            "minimumElevationInMeters", "maximumDepthInMeters", 
            "minimumDepthInMeters", "institutionCode", "collectionCode", 
            "catalogNumber", "basisOfRecordString", "collector", 
            "earliestDateCollected", "latestDateCollected", "gbifNotes")
        dims <- c(length(nodes), length(varNames))
        ans <- as.data.frame(replicate(dims[2], rep(as.character(NA), 
            dims[1]), simplify = FALSE), stringsAsFactors = FALSE)
        names(ans) <- varNames
        for (i in seq(length = dims[1])) {
            ans[i, ] <- xmlSApply(nodes[[i]], xmlValue)[varNames]
        }
        nodes <- getNodeSet(doc, "//to:Identification")
        varNames <- c("taxonName")
        dims = c(length(nodes), length(varNames))
        tax = as.data.frame(replicate(dims[2], rep(as.character(NA), 
            dims[1]), simplify = FALSE), stringsAsFactors = FALSE)
        names(tax) = varNames
        for (i in seq(length = dims[1])) {
            tax[i, ] = xmlSApply(nodes[[i]], xmlValue)[varNames]
        }
        cbind(tax, ans)
    }
    if (!is.null(ext)) {
        ex <- round(extent(ext), 5)
        ex <- paste("&minlatitude=", max(-90, ex@ymin), "&maxlatitude=", 
            min(90, ex@ymax), "&minlongitude=", max(-180, ex@xmin), 
            "&maxlongitude=", min(180, ex@xmax), sep = "")
    }
    else {
        ex <- NULL
    }
    genus <- trim(genus)
    species <- trim(species)
    gensp <- paste(genus, species)
    spec <- gsub("   ", " ", species)
    spec <- gsub("  ", " ", spec)
    spec <- gsub(" ", "%20", spec)
    spec <- paste(genus, "+", spec, sep = "")
    if (sp) 
        geo <- TRUE
    if (geo) {
        cds <- "coordinatestatus=true&coordinateissues=false"
    }
    else {
        cds <- ""
    }
    if(!is.null(dataresourcekey)) {
      cds<-paste(cds,"&dataresourcekey=",dataresourcekey,sep="") 
    }
    base <- "http://data.gbif.org/ws/rest/occurrence/"
   # url <- paste(base, "count?scientificname=", spec, cds, ex, sep = "")
    url <- paste(base, "count?", cds, ex, sep = "")
    print(url)
    if (exists("x")) 
        rm(x)
    tries <- 0
    while (!exists("x")) {
        if (tries >ntries ) {
            stop("GBIF server does not return a valid answer")
        }
        tryCatch(x <- readLines(url, warn = FALSE), error = function(e) cat("failed.\n"))
	Sys.sleep(120)
        tries <- tries + 1
    }
    x <- x[grep("totalMatched", x)]
    n <- as.integer(unlist(strsplit(x, "\""))[2])
    if (!download) {
        return(n)
    }
    if (n == 0) {
        cat(gensp, ": no occurrences found\n")
        return(invisible(NULL))
    }
    else {
        if (feedback > 0) {
            cat(gensp, ":", n, "occurrences found\n")
            flush.console()
        }
    }
    #ntries <- min(max(ntries, 1), 100)
    if (!download) {
        return(n)
    }
    nrecs <- min(max(nrecs, 1), 1000)
    iter <- n%/%nrecs
    first <- TRUE
    breakout <- FALSE
    if (start > 1) {
        ss <- floor(start/nrecs)
    }
    else {
        ss <- 0
    }
    for (group in ss:iter) {
        start <- group * nrecs
        if (feedback > 1) {
            if (group == iter) {
                end <- n - 1
            }
            else {
                end <- start + nrecs - 1
            }
            if (group == ss) {
                cat(ss, "-", end + 1, sep = "")
            }
            else {
                cat("-", end + 1, sep = "")
            }
            if ((group > ss & group%%20 == 0) | group == iter) {
                cat("\n")
            }
            flush.console()
        }
        #aurl <- paste(base, "list?scientificname=", spec, "&mode=processed&format=darwin&startindex=", format(start, scientific = FALSE), cds, ex, sep = "")
        aurl <- paste(base, "list?mode=processed&format=darwin&startindex=", format(start, scientific = FALSE), '&',cds, ex, sep = "")
        print(aurl)
        tries <- 0
        if (exists("zz")) 
            rm(zz)
        while (!exists("zz")) {
            if (tries > 1) {
                if (tries > ntries) {
                  warning("GBIF did not return the data in ", 
                    ntries, " tries\nreturning incomplete data")
                  breakout <- TRUE
                  break
                }
                else {
                  cat("(try:", tries, ")")
		  Sys.sleep(120) #give gbif time to recover
                }
            }
            tries <- tries + 1
            tryCatch(zz <- gbifxmlToDataFrame(aurl), error = function(e) cat("failed.\n"))
        }
        if (first) {
            z <- zz
            first <- FALSE
        }
        else {
            z <- rbind(z, zz)
        }
        if (breakout) {
            break
        }
    }
    d <- as.Date(Sys.time())
    z <- cbind(z, d)
    names(z) <- c("species", "continent", "country", "adm1", 
        "adm2", "locality", "lat", "lon", "coordUncertaintyM", 
        "maxElevationM", "minElevationM", "maxDepthM", "minDepthM", 
        "institution", "collection", "catalogNumber", "basisOfRecord", 
        "collector", "earliestDateCollected", "latestDateCollected", 
        "gbifNotes", "downloadDate")
    z[, "lon"] <- gsub(",", ".", z[, "lon"])
    z[, "lat"] <- gsub(",", ".", z[, "lat"])
    z[, "lon"] <- as.numeric(z[, "lon"])
    z[, "lat"] <- as.numeric(z[, "lat"])
    if (removeZeros) {
        i <- isTRUE(z[, "lon"] == 0 & z[, "lat"] == 0)
        if (geo) {
            z <- z[!i, ]
        }
        else {
            z[i, "lat"] <- NA
            z[i, "lon"] <- NA
        }
    }
    if (getAlt) {
        altfun <- function(x) {
            a <- mean(as.numeric(unlist(strsplit(gsub("-", " ", 
                gsub("m", "", (gsub(",", "", gsub("\"", "", x))))), 
                " ")), silent = TRUE), na.rm = TRUE)
            a[a == 0] <- NA
            mean(a, na.rm = TRUE)
        }
        if (feedback < 3) {
            w <- options("warn")
            options(warn = -1)
        }
        alt <- apply(z[, c("maxElevationM", "minElevationM", 
            "maxDepthM", "minDepthM")], 1, FUN = altfun)
        if (feedback < 3) 
            options(warn = w)
        z <- cbind(z[, c("species", "continent", "country", "adm1", 
            "adm2", "locality", "lat", "lon", "coordUncertaintyM")], 
            alt, z[, c("institution", "collection", "catalogNumber", 
                "basisOfRecord", "collector", "earliestDateCollected", 
                "latestDateCollected", "gbifNotes", "downloadDate", 
                "maxElevationM", "minElevationM", "maxDepthM", 
                "minDepthM")])
    }
    if (sp) {
        i <- z[!(is.na(z[, "lon"] | is.na(z[, "lat"]))), ]
        if (dim(z)[1] > 0) {
            coordinates(z) <- ~lon + lat
        }
    }
    return(z)
}

allgood<-c(paleoDB,good,wickedgood)

pullData<-function(dataresourcekey) {
	data<-gbif2(genus="*",dataresourcekey=dataresourcekey,geo=T,down=T)
	 save(data,file=paste("gbif_dataresource_",dataresourcekey,'.Rsave',sep=""),compress=TRUE)
	rm(data)
}

for (goodIndex in sequence(length(allgood))) {
	try(pullData(allgood[goodIndex])) 
}
