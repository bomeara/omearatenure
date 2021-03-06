doSimulation<-function(splits, intrinsicFn, extrinsicFn, startingValues, intrinsicValues, extrinsicValues, timeStep, saveHistory=FALSE, saveRealParams=FALSE, jobName="") {
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
if (saveHistory) {
  startVector<-c()
  endVector<-c()
  startTime<-c()
  endTime<-c()
}
numberofsteps<-floor(splits[1, 1]/timeStep)
mininterval<-min(splits[1:(dim(splits)[1]-1), 1]-splits[2:(dim(splits)[1]), 1])
#DJG# I removed two if statements that had their print statements hashed out here
#initial setup
timefrompresent=splits[1, 1]
taxa<-list(abctaxon(id=splits[1, 3], states=startingValues), abctaxon(id=splits[1, 4], states=startingValues))
splits<-splits[2:dim(splits)[1], ] #pop off top value

#start running
while(timefrompresent > 0) {
  while ((timefrompresent-timeStep)<=splits[1, 1]) { #do speciation. changed from if to while to deal with effectively polytomies
    originallength<-length(taxa)
    taxontodelete<-Inf
    originallength<-length(taxa)
    taxontodelete<-Inf
    #for (i in 1:originallength) { #need to merge this from my branch still -DG
    vec<-c(1:originallength)
    #DJG# My new function here, it pretty much is the for loop but it returns a list with two important components and a lot of nulls so it needs trimming
    delfun<-function(i){
      if (taxa[[i]]$id==splits[1, 2]) {
        taxontodelete<-i
        taxa[[originallength+1]] <- taxa[[i]]
        taxa[[originallength+2]] <- taxa[[i]]
        taxa[[originallength+1]]$id<-splits[1, 3]
        taxa[[originallength+1]]$timeSinceSpeciation<-0
        taxa[[originallength+2]]$id<-splits[1, 4]
        taxa[[originallength+2]]$timeSinceSpeciation<-0
        list(taxa,taxontodelete)
      }
    }
    #DJG# These steps below trim the list pull out the two important pieces and remove all the nulls
    foo<-lapply(vec,delfun)
    foo<-foo[!sapply(foo,is.null)]
    taxa<-foo[[1]][[1]]
    taxontodelete<-foo[[1]][[2]]

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
  otherstatefn<-function(x){
    taxa[[x]]$states
  }

  otherMatrix<-function(i){
    taxvec<-c(1:length(taxa))
    taxvec<-taxvec[-which(taxvec==i)]
    otherstatesvector<-sapply(taxvec,otherstatefn)
    otherstatesmatrix<-matrix(otherstatesvector, ncol=length(taxa[[i]]$states), byrow=TRUE) #each row represents one taxon
    newvalues<-taxa[[i]]$states+intrinsicFn(params=intrinsicValues, states=taxa[[i]]$states, timefrompresent =timefrompresent)+extrinsicFn(params=extrinsicValues, selfstates=taxa[[i]]$states, otherstates=otherstatesmatrix, timefrompresent =timefrompresent)
    taxa[[i]]$nextstates<-newvalues
    if (saveHistory) {
      startVector<-append(startVector, taxa[[i]]$states)
      endVector <-append(endVector, newvalues)
      startTime <-append(startTime, timefrompresent+timeStep)
      endTime <-append(endTime, timefrompresent)
      save(startVector, endVector, startTime, endTime, file=paste("savedHistory", jobName, ".Rdata", sep=""))
    }


    return(taxa[[i]])
  }
  taxvec<-c(1:length(taxa))
  taxa<-lapply(taxvec,otherMatrix)

  stateNextState<-function(i){
   i$states<-i$nextstates
   return(i)
  }
  taxa<-lapply(taxa,stateNextState)
  #print("------------------- step -------------------")
  #print(taxa)
  #summarizeTaxonStates(taxa)

  timefrompresent<-timefrompresent-timeStep
  timeSinceSp<-function(i) {
    i$timeSinceSpeciation<-i$timeSinceSpeciation+timeStep
    return(i)
  }
  taxa<-lapply(taxa,timeSinceSp)
}
return(summarizeTaxonStates(taxa))
}
