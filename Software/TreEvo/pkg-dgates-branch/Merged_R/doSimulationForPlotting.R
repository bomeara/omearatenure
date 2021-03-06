doSimulationForPlotting<-function(splits, intrinsicFn, extrinsicFn, startingValues, intrinsicValues, extrinsicValues, timeStep, plot=FALSE, savePlot=FALSE, saveHistory=FALSE, saveRealParams=FALSE, jobName="") {
if (saveRealParams){
	RealParams<-vector("list", 2)
	names(RealParams)<-c("matrix", "vector")	
	RealParams$vector<-c(startingValues, intrinsicValues, extrinsicValues)
	maxLength<-(max(length(startingValues), length(intrinsicValues), length(extrinsicValues)))
	RealParams$matrix<-matrix(ncol=maxLength, nrow=3)
	rownames(RealParams$matrix)<-c("startingValues", "intrinsicFn", "extrinsicFn")
	RealParams$matrix[1,]<-c(startingValues, rep(NA, maxLength-length(startingValues)))
	RealParams$matrix[2,]<-c(intrinsicValues, rep(NA, maxLength-length(intrinsicValues)))
	RealParams$matrix[3,]<-c(extrinsicValues, rep(NA, maxLength-length(extrinsicValues)))
	save(RealParams, file=paste("RealParams", jobName, ".Rdata", sep=""))
}
if (plot || savePlot || saveHistory) {
	startVector<-c()
	endVector<-c()
	startTime<-c()
	endTime<-c()
}
	numberofsteps<-floor(splits[1, 1]/timeStep)
	mininterval<-min(splits[1:(dim(splits)[1]-1), 1]-splits[2:(dim(splits)[1]), 1])
	if (numberofsteps<1000) {
		#warning(paste("You have only ", numberofsteps, " but should probably have a lot more. I would suggest decreasing timeStep to no more than ", splits[1, 1]/1000))
	}
	if (floor(mininterval/timeStep)<50) {
		#warning(paste("You have only ", floor(mininterval/timeStep), " on the shortest interval but should probably have a lot more. I would suggest decreasing timeStep to no more than ", mininterval/50))
	}
#initial setup
	timefrompresent=splits[1, 1]
	taxa<-list(abctaxon(id=splits[1, 3], states=startingValues), abctaxon(id=splits[1, 4], states=startingValues))
	splits<-splits[2:dim(splits)[1], ] #pop off top value
	
#start running
	while(timefrompresent>0) {
#print(timefrompresent)
#speciation if needed
		while ((timefrompresent-timeStep)<=splits[1, 1]) { #do speciation. changed from if to while to deal with effectively polytomies
			originallength<-length(taxa)
			taxontodelete<-Inf
			for (i in 1:originallength) {
				if (taxa[[i]]$id==splits[1, 2]) {
					taxontodelete<-i
					taxa[[originallength+1]] <- taxa[[i]]
					taxa[[originallength+2]] <- taxa[[i]]
					taxa[[originallength+1]]$id<-splits[1, 3]
					taxa[[originallength+1]]$timeSinceSpeciation<-0
					taxa[[originallength+2]]$id<-splits[1, 4]
					taxa[[originallength+2]]$timeSinceSpeciation<-0
				}
			}
#cat("taxontodelete = ", taxontodelete)
			taxa<-taxa[-1*taxontodelete]
			if(dim(splits)[1]>1) {
				splits<-splits[2:(dim(splits)[1]), ] #pop off top value
			}
			else {
				splits[1, ]<-c(-1, 0, 0, 0)
			}
#print("------------------- speciation -------------------")
#print(taxa)
#summarizeTaxonStates(taxa)
		}
#trait evolution step
		for (i in 1:length(taxa)) {
			otherstatesvector<-c()
			for (j in 1:length(taxa)) {
				if (j!=i) {
					otherstatesvector<-c(otherstatesvector, taxa[[j]]$states)
				}
			}
#print(taxa)
#print(length(otherstatesvector))
			otherstatesmatrix<-matrix(otherstatesvector, ncol=length(taxa[[i]]$states), byrow=TRUE) #each row represents one taxon
			newvalues<-taxa[[i]]$states+intrinsicFn(params=intrinsicValues, states=taxa[[i]]$states, timefrompresent =timefrompresent)+extrinsicFn(params=extrinsicValues, selfstates=taxa[[i]]$states, otherstates=otherstatesmatrix, timefrompresent =timefrompresent)
			taxa[[i]]$nextstates<-newvalues
			if (plot || savePlot || saveHistory) {
				startVector<-append(startVector, taxa[[i]]$states)
				endVector <-append(endVector, newvalues)
				startTime <-append(startTime, timefrompresent+timeStep)
				endTime <-append(endTime, timefrompresent)
				if(saveHistory){
					save(startVector, endVector, startTime, endTime, file=paste("savedHistory", jobName, ".Rdata", sep=""))
				}
			}
			
		}
		for (i in 1:length(taxa)) {

			taxa[[i]]$states<-taxa[[i]]$nextstates

			
		}
#print("------------------- step -------------------")
#print(taxa)
#summarizeTaxonStates(taxa)
		
		timefrompresent<-timefrompresent-timeStep
		for (i in 1:length(taxa)) {
			taxa[[i]]$timeSinceSpeciation<-taxa[[i]]$timeSinceSpeciation+timeStep
		}
	}
	if (plot) {
		dev.new()
		plot(x=c(min(c(startVector, endVector)), max(c(startVector, endVector))), y=c(0, max(c(startTime, endTime))), type="n", ylab="Time", xlab="Trait value", main="", bty="n")
		for (i in 1:length(startVector)) {
			lines(x=c(startVector[i], endVector[i]), y=max(c(startTime, endTime)) - c(startTime[i], endTime[i]))
		}
	}
	if (savePlot) {
		pdf(paste("SimTree", jobName, ".pdf", sep=""))	
		plot(x=c(min(c(startVector, endVector)), max(c(startVector, endVector))), y=c(0, max(c(startTime, endTime))), type="n", ylab="Time", xlab="Trait value", main="", bty="n")
		for (i in 1:length(startVector)) {
			lines(x=c(startVector[i], endVector[i]), y=max(c(startTime, endTime)) - c(startTime[i], endTime[i]))
		}
		dev.off()
	}
	return(summarizeTaxonStates(taxa))
}