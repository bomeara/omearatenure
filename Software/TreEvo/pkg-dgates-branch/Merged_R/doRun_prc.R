##Should be running if checkpoint=TRUE and the correct workspace image is specified

#TreeYears = 1000000 if tree length is in in millions of years, 1000 if in thousand, etc.
#the doRun_prc function takes input from the user and then automatically guesses optimal parameters, though user overriding is also possible.
#the guesses are used to do simulations near the expected region. If omitted, they are set to the midpoint of the input parameter matrices

doRun_prc<-function(phy, traits, intrinsicFn, extrinsicFn, startingPriorsValues, startingPriorsFns, intrinsicPriorsValues, intrinsicPriorsFns, extrinsicPriorsValues, extrinsicPriorsFns, startingValuesGuess=c(), intrinsicValuesGuess=c(), extrinsicValuesGuess=c(), TreeYears=1e+04, numParticles=300, standardDevFactor=0.20, StartSims=300, plot=FALSE, epsilonProportion=0.7, epsilonMultiplier=0.7, nStepsPRC=5, jobName=NA, stopRule=FALSE, stopValue=0.05, vipthresh=0.8, multicore=FALSE, coreLimit=NA, startFromCheckpoint=FALSE, checkpointFile=NA) {



if (startFromCheckpoint==FALSE){
  if (!is.binary.tree(phy)) {
    print("Warning: Tree is not fully dichotomous")
}


  dataGenerationStep<-0  #DJG# added so that startfromcheckpoint can pick up after initial sims
  timeStep<-1/TreeYears			
	
  splits<-getSimulationSplits(phy) #initialize this info
		
  #figure out number of free params		
  numberParametersTotal<-dim(startingPriorsValues)[2] +  dim(intrinsicPriorsValues)[2] + dim(extrinsicPriorsValues)[2] 
  numberParametersFree<-numberParametersTotal
  numberParametersStarting<-0
  numberParametersIntrinsic<-0
  numberParametersExtrinsic<-0
  freevariables<-matrix(data=NA, nrow=2, ncol=0)
  titlevector<-c()
  freevector<-c()
			
  #create PriorMatrix
  namesForPriorMatrix<-c() 
  PriorMatrix<-matrix(c(startingPriorsFns, intrinsicPriorsFns, extrinsicPriorsFns), nrow=1, ncol=numberParametersTotal)
  for (a in 1:dim(startingPriorsValues)[2]) {
    namesForPriorMatrix<-c(paste("StartingStates", a, sep=""))
  }
  for (b in 1:dim(intrinsicPriorsValues)[2]) {
    namesForPriorMatrix<-append(namesForPriorMatrix, paste("IntrinsicValue", b, sep=""))
  }
  #print(extrinsicPriorsValues)
  for (c in 1:dim(extrinsicPriorsValues)[2]) {
    namesForPriorMatrix <-append(namesForPriorMatrix, paste("ExtrinsicValue", c, sep=""))
  }
  PriorMatrix<-rbind(PriorMatrix, cbind(startingPriorsValues, intrinsicPriorsValues, extrinsicPriorsValues))
  colnames(PriorMatrix)<-namesForPriorMatrix
  rownames(PriorMatrix)<-c("shape", "value1", "value2")

  #Calculate freevector				
  for (i in 1:dim(startingPriorsValues)[2]) {
    priorFn<-match.arg(arg=startingPriorsFns[i],choices=c("fixed", "uniform", "normal", "lognormal", "gamma", "exponential"),several.ok=FALSE)
    if (priorFn=="fixed") {
      numberParametersFree<-numberParametersFree-1
      freevector<-c(freevector, FALSE)
    }
    else {
      numberParametersStarting<-numberParametersStarting+1
      freevariables<-cbind(freevariables, startingPriorsValues[, i])
      titlevector <-c(titlevector, paste("Starting", numberParametersStarting))
      freevector<-c(freevector, TRUE)
    }
  }
  for (i in 1:dim(intrinsicPriorsValues)[2]) {
    priorFn<-match.arg(arg=intrinsicPriorsFns[i],choices=c("fixed", "uniform", "normal", "lognormal", "gamma", "exponential"),several.ok=FALSE)
    if (priorFn=="fixed") {
      numberParametersFree<-numberParametersFree-1
      freevector<-c(freevector, FALSE)
    }
    else {
      numberParametersIntrinsic<-numberParametersIntrinsic+1
      freevariables<-cbind(freevariables, intrinsicPriorsValues[, i])
      titlevector <-c(titlevector, paste("Intrinsic", numberParametersIntrinsic))
      freevector<-c(freevector, TRUE)
    }
  }
  for (i in 1:dim(extrinsicPriorsValues)[2]) {
    priorFn<-match.arg(arg=extrinsicPriorsFns[i],choices=c("fixed", "uniform", "normal", "lognormal", "gamma", "exponential"),several.ok=FALSE)
    if (priorFn=="fixed") {
      numberParametersFree<-numberParametersFree-1
      freevector<-c(freevector, FALSE)
    }
    else {
      numberParametersExtrinsic<-numberParametersExtrinsic+1
      freevariables<-cbind(freevariables, extrinsicPriorsValues[, i])
      titlevector <-c(titlevector, paste("Extrinsic", numberParametersExtrinsic))
      freevector<-c(freevector, TRUE)
    }
  }
		
  #initialize weighted mean sd matrices
  weightedMeanParam<-matrix(nrow=nStepsPRC, ncol=numberParametersTotal)
  colnames(weightedMeanParam)<-namesForPriorMatrix
  rownames(weightedMeanParam)<-paste("Gen", c(1: nStepsPRC), sep="")
  param.stdev<-matrix(nrow=nStepsPRC, ncol=numberParametersTotal)
  colnames(param.stdev)<-namesForPriorMatrix
  rownames(param.stdev)<-paste("Gen", c(1: nStepsPRC), sep="")

  #initialize guesses, if needed
  if (length(startingValuesGuess)==0) { #if no user guesses, try pulling a value from the prior
    startingValuesGuess<-rep(NA,length(startingPriorsFns))
    for (i in 1:length(startingPriorsFns)) {
      startingValuesGuess[i]<-pullFromPrior(startingPriorsValues[,i],startingPriorsFns[i])
    }
  }
  if (length(intrinsicValuesGuess)==0) { #if no user guesses, try pulling a value from the prior
    intrinsicValuesGuess<-rep(NA,length(intrinsicPriorsFns))
    for (i in 1:length(intrinsicPriorsFns)) {
      intrinsicValuesGuess[i]<-pullFromPrior(intrinsicPriorsValues[,i],intrinsicPriorsFns[i])
    }
  }
  if (length(extrinsicValuesGuess)==0) { #if no user guesses, try pulling a value from the prior
    extrinsicValuesGuess<-rep(NA,length(extrinsicPriorsFns))
    for (i in 1:length(extrinsicPriorsFns)) {
      extrinsicValuesGuess[i]<-pullFromPrior(extrinsicPriorsValues[,i],extrinsicPriorsFns[i])
    }
  }

  if (is.na(StartSims)) {
    StartSims<-1000*numberParametersFree
  }


	
			#---------------------- Initial Simulations (Start) ------------------------------
			#See Wegmann et al. Efficient Approximate Bayesian Computation Coupled With Markov Chain Monte Carlo Without Likelihood. Genetics (2009) vol. 182 (4) pp. 1207-1218 for more on the method. Note, though, that we are not doing PLS, only Box-Cox transformation
  nrepSim<-StartSims #Used to be = StartSims*((2^try)/2), If initial simulations are not enough, and we need to try again then new analysis will double number of initial simulations
  input.data<-rbind(jobName, length(phy[[3]]), nrepSim, TreeYears, epsilonProportion, epsilonMultiplier, nStepsPRC, numParticles, standardDevFactor)		
  cat(paste("Number of initial simulations set to", nrepSim, "\n"))
  cat("Doing simulations:")
  Time<-proc.time()[[3]]
  trueFreeValues<-matrix(nrow=0, ncol= numberParametersFree)
  summaryValues<-matrix(nrow=0, ncol=length(summaryStatsLong(phy, traits))) #set up initial sum stats as length of SSL of original data
  trueFreeValuesANDSummaryValues<-parallelSimulation(nrepSim, coreLimit, splits, phy, startingPriorsValues, intrinsicPriorsValues, extrinsicPriorsValues, startingPriorsFns, intrinsicPriorsFns, extrinsicPriorsFns, freevector, timeStep, intrinsicFn, extrinsicFn, multicore)
  cat("\n\n")

  save(trueFreeValues,summaryValues,file=paste("CompletedSimulations",jobName,".Rdata",sep=""))
  simTime<-proc.time()[[3]]-Time
  cat(paste("Initial simulations took", round(simTime, digits=3), "seconds"), "\n")

  #separate the simulation results: true values and the summary values
  trueFreeValuesMatrix<-trueFreeValuesANDSummaryValues[,1:numberParametersFree]
  summaryValuesMatrix<-trueFreeValuesANDSummaryValues[,-1:-numberParametersFree]
  #while(sink.number()>0) {sink()}

			#---------------------- Initial Simulations (End) ------------------------------


			#---------------------- Box-Cox transformation (Start) ------------------------------
  boxcoxEstimates<-boxcoxEstimation(summaryValuesMatrix)
  boxcoxAddition<-boxcoxEstimates$boxcoxAddition
  boxcoxLambda<-boxcoxEstimates$boxcoxLambda
  boxcoxSummaryValuesMatrix<-boxcoxEstimates$boxcoxSummaryValues

  #save(trueFreeValues, file="tFV")
  #save(boxcoxSummaryValues, file="bcSV")
				
			#---------------------- Box-Cox transformation (End) ------------------------------


			#----------------- PLS regression: find best set of summary stats to use (Start) -----------------
			#Use mixOmics to to find the optimal set of summary stats. Note that this uses a different package (mixOmics rather than pls than that used by Weggman et al. because this package can calculate variable importance in projection and deals fine with NAs)

  library("mixOmics")
  getVipSingleColumn<-function(trueFreeValuesColumn, boxcoxSummaryValuesMatrix) {
    return(vip(pls(X=boxcoxSummaryValuesMatrix, Y=trueFreeValuesColumn, ncomp=1)))
  }
	
  allVip<-apply(trueFreeValuesMatrix, 2, getVipSingleColumn, boxcoxSummaryValuesMatrix)
  whichVip<-(allVip>vipthresh)
  rownames(whichVip)<-sumStatNames(phy)
	
  #Now using abcDistance to calculate euclid distance rather than abc()
  boxcoxOriginalSummaryStats<-boxcoxTransformation(summaryStatsLong(phy=phy, data=traits), boxcoxAddition, boxcoxLambda) #boxcox empirical data 
  calculatedDist<-abcDistance(trueFreeValuesMatrix, whichVip, boxcoxOriginalSummaryStats, boxcoxSummaryValuesMatrix) 
  distanceVector<-calculatedDist$abcDistances
  #print(calculatedDist)


			#----------------- PLS regression: find best set of summary stats to use (End) -----------------
			
			
			#----------------- Find distribution of distances (Start) ----------------------
	#calculate Raw Distances (note: these distances are the SAME when you do them together as they are when you do them sqrt(sum(seperate^2)). )
	
  epsilonDistance<-quantile(distanceVector, probs=epsilonProportion) #this gives the distance such that epsilonProportion of the simulations starting from a given set of values will be rejected 
  toleranceVector<-rep(epsilonDistance, nStepsPRC)
  if(nStepsPRC>1){
    for (step in 2:nStepsPRC) {
      toleranceVector[step]<-toleranceVector[step-1]*epsilonMultiplier
    }
  }

  save(list= ls(), file=paste("WS", jobName, ".Rdata", sep=""))

}#if start from checkpoint = FALSE bracket

#DJG# start from checkpoint works but loading the saved workspace will overwrite arguments you've most recently made, so I pick out the three that would probably be the most important: the jobname so you save to a new workspace, nStepsPRC so you can add generations, and startFromCheckpoint because you don't want that immediately turning off. It may be worth it to add more arguments like multicore or number of particles but for now those are determined by your saved workspace

if (startFromCheckpoint){	
  job<-jobName 
  steps<-nStepsPRC 
  check<-startFromCheckpoint 
  load(checkpointFile)  
  startFromCheckpoint<-check  
  stepdif<-c(1:(steps-nStepsPRC)) 
  for (x in stepdif){ #DJG# this is only if you're adding more generations  
    param.stdev<-rbind(param.stdev,0) 
    weightedMeanParam<-rbind(weightedMeanParam,0)
  }
  rownames(param.stdev)<-paste("Gen", c(1: steps), sep="")
  rownames(weightedMeanParam)<-paste("Gen", c(1: steps), sep="")
  nStepsPRC<-steps 
  jobName<-job
  toleranceVector<-rep(epsilonDistance, nStepsPRC)
  if(nStepsPRC>1){ #DJG# just remaking the tolerance vector here
    for (step in 2:nStepsPRC) {
      toleranceVector[step]<-toleranceVector[step-1]*epsilonMultiplier
    }
  }		
} #if (startFromCheckpoint) bracket

if (dataGenerationStep==0){
			#----------------- Find distribution of distances (End) ---------------------
			
			#------------------ ABC-PRC (Start) ------------------
			#do not forget to use boxcoxLambda, and plsResult when computing distances
			
  nameVector<-c("generation", "attempt", "id", "parentid", "distance", "weight")
  if (plot) {
    plot(x=c(min(intrinsicPriorsValues), max(intrinsicPriorsValues)), y=c(0, 5*max(toleranceVector)), type="n")
  }
  for (i in 1:dim(startingPriorsValues)[2]) {
    nameVector<-append(nameVector, paste("StartingStates", i, sep=""))
  }
  for (i in 1:dim(intrinsicPriorsValues)[2]) {
    nameVector<-append(nameVector, paste("IntrinsicValue", i, sep=""))
  }
  for (i in 1:dim(extrinsicPriorsValues)[2]) {
    nameVector<-append(nameVector, paste("ExtrinsicValue", i, sep=""))
  }
  particleWeights=rep(0, numParticles) #stores weights for each particle. Initially, assume infinite number of possible particles (so might not apply in discrete case)
  particleParameters<-matrix(nrow=numParticles, ncol=dim(startingPriorsValues)[2] +  dim(intrinsicPriorsValues)[2] + dim(extrinsicPriorsValues)[2]) #stores parameters in model for each particle
  particleDistance=rep(NA, numParticles)
  particle<-1
  attempts<-0
  particleDataFrame<-data.frame()
  cat("\n\n\nsuccesses", "attempts", "expected number of attempts required\n\n\n")
  start.time<-proc.time()[[3]]
  particleList<-list()
			
  while (particle<=numParticles) { 
    #DJG# This is the function that allows for parallelization of the particle steps. Instead of doing a single simulation then running that particle through the particle acceptance step it does however many cores you have worth of particles then runs the list through the subsequent steps. The particle simulation step is the time intensive step so it at least allows for that to be done in parallel.
    particleFn<-function(){ 
      newparticleList<-list(abcparticle(id=particle, generation=1, weight=0))
      newparticleList[[1]]<-initializeStatesFromMatrices(newparticleList[[1]], startingPriorsValues, startingPriorsFns, intrinsicPriorsValues, intrinsicPriorsFns, extrinsicPriorsValues, extrinsicPriorsFns)
      boxcoxOneSimSumStats<-boxcoxTransformation(summaryStatsLong(phy, convertTaxonFrameToGeigerData(doSimulation(splits, intrinsicFn, extrinsicFn, newparticleList[[1]]$startingValues, newparticleList[[1]]$intrinsicValues, newparticleList[[1]]$extrinsicValues, timeStep), phy)), boxcoxAddition, boxcoxLambda)
      newparticleList[[1]]$distance<-abcDistance(trueFreeValuesMatrix, whichVip, boxcoxOriginalSummaryStats, rbind(boxcoxOneSimSumStats, boxcoxOneSimSumStats))$abcDistances[1] #trueFreeValuesMatrix is used here just for finding dims, not distances.  #silly way around the one-row matrix issue--rbind the same data and then extract the first element.  
      #boxcoxSummaryValuesMatrix<-matrix(boxcoxParticleSummaryStats,nrow=1)
      #newparticleList[[1]]$distance<-dist(matrix(c(boxcoxplsSummary(oneSimSumStats, plsResult, boxcoxLambda, boxcoxAddition, whichVip), boxcoxplsOriginalSummaryStats), nrow=2, byrow=TRUE))[1]
      return(newparticleList[[1]])
    }
    #DJG# the foreach function which is your actual parallelization. This could be made an mclapply or a parLapply function (if you wanted to run parallel on Windows) very easily but would require some different registering of cores.
    listpartvec<-foreach(1:coreLimit) %dopar% particleFn() 

    for(newparticleList in listpartvec){  #DJG# this is the particle acceptance step but if multicore=TRUE you're feeding it a list of particles instead of a single particle. Check out McCallum and Weston's book Parallel R for more details
      attempts<-attempts+1
                                
      if (is.na(newparticleList$distance)) {
        warning("newparticleList$distance = NA, likely an underflow/overflow problem")
        newparticleList$id <-  (-1)
        newparticleList$weight<- 0
      }
      else if (is.na(toleranceVector[1])) {
        warning("toleranceVector[1] = NA")
        newparticleList$id <- (-1)
        newparticleList$weight <- 0
      }					
      else if ((newparticleList$distance) < toleranceVector[1]) {
        newparticleList$id <- particle
        newparticleList$weight <- 1/numParticles
        particleWeights[particle] <- 1/numParticles
        particle<-particle+1
        particleList[[length(particleList)+1]]<-newparticleList
      }
      else {
        newparticleList$id <- (-1)
        newparticleList$weight <- 0
      }
      #while(sink.number()>0) {sink()}
      #print(newparticleList)
      vectorForDataFrame<-c(1, attempts, newparticleList$id, 0, newparticleList$distance, newparticleList$weight, newparticleList$startingValues, newparticleList$intrinsicValues, newparticleList$extrinsicValues)
      #cat("\n\nlength of vectorForDataFrame = ", length(vectorForDataFrame), "\n", "length of startingValues = ", length(startingValues), "\nlength of intrinsicValues = ", length(intrinsicValues), "\nlength of extrinsicValues = ", length(extrinsicValues), "\ndistance = ", newparticleList[[1]]$distance, "\nweight = ", newparticleList[[1]]$weight, "\n", vectorForDataFrame, "\n")
      particleDataFrame<-rbind(particleDataFrame, vectorForDataFrame)
      cat(particle-1, attempts, floor(numParticles*attempts/particle), newparticleList$startingValues, newparticleList$intrinsicValues, newparticleList$extrinsicValues, newparticleList$distance, "\n")
    } #DJG# Dan's for loop bracket	
  } #while (particle<=numParticles) bracket
  names(particleDataFrame)<-nameVector
  time<-proc.time()[[3]]-start.time
  time.per.gen<-time
  rejects.gen.one<-(dim(subset(particleDataFrame, particleDataFrame$id<0))[1])/(dim(subset(particleDataFrame,))[1])
  rejects<-c()
  for (i in 1:numberParametersTotal){
    param.stdev[1,i]<-c(sd(subset(particleDataFrame, particleDataFrame$id>0)[,6+i]))
    weightedMeanParam[1,i]<-weighted.mean(subset(particleDataFrame, particleDataFrame$id>0)[,6+i], subset(particleDataFrame, particleDataFrame$id>0)[,6])
    #c(mean(subset(particleDataFrame, X3>0)[,7:dim(particleDataFrame)[2]])/subset(particleDataFrame, X3>0)[,6])
  }
		
  dataGenerationStep<-1 #DJG# To aid with checkpointing purposes
  save(list=ls(),file=paste("WS", jobName, ".Rdata", sep=""))
  prcResults<-vector("list")
  prcResults$input.data<-input.data
  prcResults$PriorMatrix<-PriorMatrix
  prcResults$particleDataFrame<-particleDataFrame
  names(prcResults$particleDataFrame)<-nameVector
  prcResults$toleranceVector<-toleranceVector
  prcResults$phy<-phy
  prcResults$traits<-traits
  prcResults$simTime<-simTime
  prcResults$time.per.gen<-time.per.gen
  prcResults$whichVip<-whichVip
			
  save(prcResults, file=paste("partialResults", jobName, ".txt", sep=""))
} #if datagenerationstep==0 bracket

while (dataGenerationStep < nStepsPRC) {
  dataGenerationStep<-dataGenerationStep+1
  cat("\n\n\n", "STARTING DATA GENERATION STEP ", dataGenerationStep, "\n\n\n")
  start.time<-proc.time()[[3]]
  particleWeights<-particleWeights/(sum(particleWeights,na.rm=TRUE)) #normalize to one
  cat("particleWeights\n", particleWeights, "\n\n")
  oldParticleList<-particleList
  oldParticleWeights<-particleWeights
  particleWeights=rep(0, numParticles) #stores weights for each particle. Initially, assume infinite number of possible particles (so might not apply in discrete case)
  particleParameters<-matrix(nrow=numParticles, ncol=dim(startingPriorsValues)[2] +  dim(intrinsicPriorsValues)[2] + dim(extrinsicPriorsValues)[2]) #stores parameters in model for each particle
  particleDistance=rep(NA, numParticles)
  particle<-1
  attempts<-0
  cat("successes", "attempts", "expected number of attempts required\n")
  particleList<-list()
  weightScaling=0;
  while (particle<=numParticles) {
    #DJG# This is function to allow for running in parallel again
    particleFun<-function(){ 
      particleToSelect<-which.max(as.vector(rmultinom(1, size = 1, prob=oldParticleWeights)))
      #cat("particle to select = ", particleToSelect, "\n")
      #cat("dput(oldParticleList)\n")
      #dput(oldParticleList)
      #cat("dput(oldParticleList[particleToSelect])\n")
      #dput(oldParticleList[particleToSelect])
      #cat("dput(oldParticleList[[particleToSelect]])\n")
      #dput(oldParticleList[[particleToSelect]])
      newparticleList<-list(oldParticleList[[particleToSelect]])
      #cat("dput(newparticleList[[1]])\n")
      #dput(newparticleList[[1]])
      #cat("mutateStates\n")
      newparticleList[[1]]<-mutateStates(newparticleList[[1]], startingPriorsValues, startingPriorsFns, intrinsicPriorsValues, intrinsicPriorsFns, extrinsicPriorsValues, extrinsicPriorsFns, standardDevFactor)
      boxcoxOneSimSumStats<-boxcoxTransformation(summaryStatsLong(phy, convertTaxonFrameToGeigerData(doSimulation(splits, intrinsicFn, extrinsicFn, newparticleList[[1]]$startingValues, newparticleList[[1]]$intrinsicValues, newparticleList[[1]]$extrinsicValues, timeStep), phy)), boxcoxAddition, boxcoxLambda)
      #cat("dput(newparticleList[[1]]) AFTER MUTATE STATES\n")
      #dput(newparticleList[[1]])
      newparticleList[[1]]$distance<-abcDistance(trueFreeValuesMatrix, whichVip, boxcoxOriginalSummaryStats, rbind(boxcoxOneSimSumStats, boxcoxOneSimSumStats))$abcDistances[1] #trueFreeValuesMatrix is used here just for finding dims, not distances.  #silly way around the one-row matrix issue--rbind the same data and then extract the first element.  
      #dist(matrix(c(boxcoxplsSummary(summaryStatsLong(phy, convertTaxonFrameToGeigerData(doSimulation(splits, intrinsicFn, extrinsicFn, newparticleList[[1]]$startingValues, newparticleList[[1]]$intrinsicValues, newparticleList[[1]]$extrinsicValues, timeStep), phy)), plsResult, boxcoxLambda, boxcoxAddition, whichVip), boxcoxplsOriginalSummaryStats), nrow=2, byrow=TRUE))[1]
      
      #DJG# I'm not sure if plotting will work in multicore...
      if (plot) {
        plotcol="grey"
        if (newparticleList[[1]]$distance<toleranceVector[dataGenerationStep]) {
          plotcol="black"
          if (dataGenerationStep==length(toleranceVector)) {
            plotcol="red"
          }
        }
        text(x=newparticleList[[1]]$intrinsicValues, y=newparticleList[[1]]$distance, labels= dataGenerationStep, col=plotcol) 
      }
      return(list(newparticleList[[1]],particleToSelect)) #DJG# here I need two things back from this function newparticleList and particleToSelect
    }
    listPartVecs<- foreach (1:coreLimit) %dopar% particleFun()
    #DJG# since I'm returning two important items I need to split the list 
    lPVfun<- function(x) return(x[[1]]) 
    pTSfun<-function(y) return(y[[2]]) 
    newparticleList<-lapply(listPartVecs,lPVfun)
    particlesToSelect<-lapply(listPartVecs,pTSfun)
    for (x in 1:length(newparticleList)){ #DJG# again iterate through the particles you've created above
      attempts<-attempts+1
      #cat("dput(newparticleList) AFTER computeABCDistance\n")
      #dput(newparticleList)
						
      if (is.na(newparticleList[[x]]$distance)) {
        #cat("Error with Geiger?  newparticleList$distance = NA\n")
        #while(sink.number()>0) {sink()}
        #warning("newparticleList$distance = NA")
        newparticleList[[x]]$id <- (-1)
        newparticleList[[x]]$weight <- 0
      }
      else if (newparticleList[[x]]$distance < toleranceVector[dataGenerationStep]) {
        newparticleList[[x]]$id <- particle
        particle<-particle+1
        particleList[[length(particleList)+1]]<- newparticleList[[x]] #DJG# the append that was here was acting up in my loop so I'm just growing this list instead
        #now get weights, using correction in Sisson et al. 2007
        newWeight=0
        for (i in 1:length(oldParticleList)) {
          lnTransitionProb=log(1)
          for (j in 1:length(newparticleList[[x]]$startingValues)) {
            newvalue<-newparticleList[[x]]$startingValues[j]
            meantouse= oldParticleList[[i]]$startingValues[j]
            if (startingPriorsFns[j]=="uniform") {
              sdtouse<-standardDevFactor*((max(startingPriorsValues[,j])-min(startingPriorsValues[,j]))/sqrt(12))
              #print(paste("startingPriorFn is uniform and sdtouse =", sdtouse))
            }
            else if (startingPriorsFns[j]=="exponential") {
              sdtouse<-standardDevFactor*(1/startingPriorsValues[,j])
              #print(paste("startingPriorFn is exponential and sdtouse =", sdtouse))
            }
            else {
              sdtouse<-standardDevFactor*(startingPriorsValues[2,j])
            }
																
            lnlocalTransitionProb=dnorm(newvalue, mean=meantouse, sd=sdtouse,log=TRUE) - ((log(1)/pnorm(min(startingPriorsValues[, j]), mean=meantouse, sd=sdtouse, lower.tail=T, log.p=T))* pnorm(max(startingPriorsValues[,j]), mean=meantouse , sd=sdtouse, lower.tail=F, log.p=T))
				
            if (lnlocalTransitionProb == "NaN") {  #to prevent lnlocalTransitionProb from being NaN (if pnorm=0)
              lnlocalTransitionProb<-.Machine$double.xmin
            }
            if (min(startingPriorsValues[, j])==max(startingPriorsValues[, j])) {
              lnlocalTransitionProb=log(1)
            } 
            lnTransitionProb<-lnTransitionProb+lnlocalTransitionProb
            if(!is.finite(lnTransitionProb) || is.na(lnlocalTransitionProb)) {
              print(paste("issue with lnTransitionProb: lnlocalTransitionProb = ",lnlocalTransitionProb," lnTransitionProb = ",lnTransitionProb))
            }
          } # for (j in 1:length(newparticleList[[x]]$startingValues)) bracket
          for (j in 1:length(newparticleList[[x]]$intrinsicValues)) {
            newvalue<-newparticleList[[x]]$intrinsicValues[j]
            meantouse= oldParticleList[[i]]$intrinsicValues[j]
            if (intrinsicPriorsFns[j]=="uniform") {
              sdtouse<-standardDevFactor*((max(intrinsicPriorsValues[,j])-min(intrinsicPriorsValues[,j]))/sqrt(12))
            }
            else if (intrinsicPriorsFns[j]=="exponential") {
              sdtouse<-standardDevFactor*(1/intrinsicPriorsValues[,j])
            }
            else {
              sdtouse<-standardDevFactor*(intrinsicPriorsValues[2,j])
            }
            lnlocalTransitionProb=dnorm(newvalue, mean= meantouse, sd= sdtouse,log=TRUE)-((log(1)/pnorm(min(intrinsicPriorsValues[, j]), mean=meantouse , sd=sdtouse, lower.tail=T, log.p=T)) * pnorm(max(intrinsicPriorsValues[,j]), mean=meantouse , sd=sdtouse, lower.tail=F, log.p=T))
				
            if (lnlocalTransitionProb == "NaN") {  #to prevent lnlocalTransitionProb from being NaN (if pnorm=0)
              lnlocalTransitionProb<-.Machine$double.xmin
            }
            if (min(intrinsicPriorsValues[, j])==max(intrinsicPriorsValues[, j])) {
              lnlocalTransitionProb=log(1)
            } 
            lnTransitionProb<-lnTransitionProb+lnlocalTransitionProb
            if(!is.finite(lnTransitionProb) || is.na(lnlocalTransitionProb)) {
              print(paste("issue with lnTransitionProb: lnlocalTransitionProb = ",lnlocalTransitionProb," lnTransitionProb = ",lnTransitionProb))
            }
          } # for (j in 1:length(newparticleList[[x]]$intrinsicValues)) bracket
          for (j in 1:length(newparticleList[[x]]$extrinsicValues)) {
            newvalue<-newparticleList[[x]]$extrinsicValues[j]
            meantouse= oldParticleList[[i]]$extrinsicValues[j]
            if (extrinsicPriorsFns[j]=="uniform") {
              sdtouse<-standardDevFactor*((max(extrinsicPriorsValues[,j])-min(extrinsicPriorsValues[,j]))/sqrt(12))
            } 
            else if (extrinsicPriorsFns[j]=="exponential") {
              sdtouse<-standardDevFactor*(1/extrinsicPriorsValues[,j])
            }
            else {
              sdtouse<-standardDevFactor*(extrinsicPriorsValues[2,j])
            }
            lnlocalTransitionProb=dnorm(newvalue, mean= meantouse, sd= sdtouse,log=TRUE)-((log(1)/pnorm(min(extrinsicPriorsValues[,j]), mean=meantouse , sd=sdtouse, lower.tail=T, log.p=T)) * pnorm(max(extrinsicPriorsValues[,j]), mean=meantouse , sd=sdtouse, lower.tail=F, log.p=T))
            if (lnlocalTransitionProb == "NaN") {  #to prevent lnlocalTransitionProb from being NaN (if pnorm=0)
              lnlocalTransitionProb<-.Machine$double.xmin
            }
            if (min(extrinsicPriorsValues[, j])==max(extrinsicPriorsValues[, j])) {
              lnlocalTransitionProb=log(1)
            } 
            lnTransitionProb<-lnTransitionProb+lnlocalTransitionProb
              if(!is.finite(lnTransitionProb) || is.na(lnlocalTransitionProb)) {
                print(paste("issue with lnTransitionProb: lnlocalTransitionProb = ",lnlocalTransitionProb," lnTransitionProb = ",lnTransitionProb))
              }
            } # for (j in 1:length(newparticleList[[x]]$extrinsicValues)) bracket                                       
            newWeight<-newWeight+(oldParticleList[[i]]$weight)*exp(lnTransitionProb)
          } #for (i in 1:length(oldParticleList)) bracket
        if (!is.finite(newWeight)) {
          print(paste("warning: newWeight is ",newWeight))
        }
        newparticleList[[x]]$weight<- newWeight
	particleWeights[particle-1]<-newWeight
	weightScaling<-weightScaling+newWeight
      } #else if (newparticleList$distance < toleranceVector[dataGenerationStep]) bracket
      else {
        newparticleList[[x]]$id<- (-1)
        newparticleList[[x]]$weight<-0
      }
      #while(sink.number()>0) {sink()}
      #print(newparticleList)  
      vectorForDataFrame<-c(dataGenerationStep, attempts,newparticleList[[x]]$id,particlesToSelect[[x]], newparticleList[[x]]$distance, newparticleList[[x]]$weight, newparticleList[[x]]$startingValues, newparticleList[[x]]$intrinsicValues, newparticleList[[x]]$extrinsicValues)
      save(vectorForDataFrame, file="vector.Rdata")
      #cat("\n\nlength of vectorForDataFrame = ", length(vectorForDataFrame), "\n", "length of startingValues = ", length(startingValues), "\nlength of intrinsicValues = ", length(intrinsicValues), "\nlength of extrinsicValues = ", length(extrinsicValues), "\ndistance = ", newparticleList$distance, "\nweight = ", newparticleList$weight, "\n", vectorForDataFrame, "\n")
      save(particleDataFrame, file="pDF.Rdata")
      particleDataFrame<-rbind(particleDataFrame, vectorForDataFrame) #NOTE THAT WEIGHTS AREN'T NORMALIZED IN THIS DATAFRAME
      cat(particle-1, attempts, floor(numParticles*attempts/particle), newparticleList[[x]]$startingValues, newparticleList[[x]]$intrinsicValues, newparticleList[[x]]$extrinsicValues, newparticleList[[x]]$distance, "\n")
												
    } #DJG# dan's for loop bracket
  } #while (particle<=numParticles) bracket
  
  particleDataFrame[which(particleDataFrame$generation==dataGenerationStep), ]$weight<-particleDataFrame[which(particleDataFrame$generation==dataGenerationStep), ]$weight/(sum(particleDataFrame[which(particleDataFrame$generation==dataGenerationStep), ]$weight))
				
  time2<-proc.time()[[3]]-start.time
  time.per.gen<-c(time.per.gen, time2)
  #rejects.per.gen<-(dim(subset(particleDataFrame, particleDataFrame$id<0))[1])/(dim(subset(particleDataFrame[which(particleDataFrame$generation==dataGenerationStep),],))[1])
  #rejects<-c(rejects, rejects.per.gen)
  sub1<-subset(particleDataFrame, particleDataFrame$generation==dataGenerationStep)
  sub2<-subset(sub1, sub1$id>0)
						
  for (i in 1:numberParametersTotal){
    param.stdev[dataGenerationStep,i]<-c(sd(sub2[,6+i]))
    weightedMeanParam[dataGenerationStep,i]<-weighted.mean(sub2[,6+i], sub2[,6])
  }
				
  if (stopRule){	#this will stop the PRC from running out to max number of generations if all params are below stopValue
    FF<-rep(1, dim(weightedMeanParam)[2])
    for (check.weightedMeanParam in 1:length(FF)){
      if (is.na(abs(weightedMeanParam[dataGenerationStep, check.weightedMeanParam]-weightedMeanParam[dataGenerationStep-1, check.weightedMeanParam])/mean(weightedMeanParam[dataGenerationStep, check.weightedMeanParam], weightedMeanParam[dataGenerationStep-1, check.weightedMeanParam]) <= stopValue) && mean(weightedMeanParam[dataGenerationStep, check.weightedMeanParam], weightedMeanParam[dataGenerationStep-1, check.weightedMeanParam]) == 0) {  #this && is here to make sure any NAs are from fixed params and not miscalculations.   
        FF[check.weightedMeanParam]<-0
      }
      else if (abs(weightedMeanParam[dataGenerationStep, check.weightedMeanParam]-weightedMeanParam[dataGenerationStep-1, check.weightedMeanParam])/mean(weightedMeanParam[dataGenerationStep, check.weightedMeanParam], weightedMeanParam[dataGenerationStep-1, check.weightedMeanParam]) <= stopValue){
        FF[check.weightedMeanParam]<-0
      }
      #print(FF)
    }
    if (sum(FF)==0){
      cat("\n\n\nweightedMeanParam is < ", stopValue, "Analysis is being terminated at", dataGenerationStep, "instead of continuing to ", nStepsPRC, "\n\n\n")
      dataGenerationStep<-nStepsPRC	
    }
  }	
						
  save(list= ls(),file=paste("WS", jobName, ".Rdata", sep=""))
  prcResults<-vector("list")
  prcResults$input.data<-input.data
  prcResults$PriorMatrix<-PriorMatrix
  prcResults$particleDataFrame<-particleDataFrame
  names(prcResults$particleDataFrame)<-nameVector
  prcResults$toleranceVector<-toleranceVector
  prcResults$phy<-phy
  prcResults$traits<-traits
  prcResults$simTime
  prcResults$time.per.gen<-time.per.gen
  prcResults$whichVip<-whichVip
			
  #save(prcResults, file=paste("partialResults", jobName, ".txt", sep=""))	
} #while (dataGenerationStep < nStepsPRC) bracket
			
		
names(particleDataFrame)<-nameVector
if(plot) {
  quartz()
  plot(x=c(min(intrinsicPriorsValues), max(intrinsicPriorsValues)), y=c(0, 1), type="n")
  for (i in 1:(length(toleranceVector)-1)) {
    graycolor<-gray(0.5*(length(toleranceVector)-i)/length(toleranceVector))
    lines(density(subset(particleDataFrame, particleDataFrame$generation==i)[, 8]), col= graycolor)
  }
  lines(density(subset(particleDataFrame, particleDataFrame$generation==length(toleranceVector))[, 8]), col= "red")
} 
				
			#---------------------- ABC-PRC (End) --------------------------------
			
				
#Calculate summary statistics on final generation particles
FinalParamPredictions_CredInt<-CredInt(particleDataFrame)
FinalParamPredictions_HPD<-HPD(particleDataFrame)
input.data<-rbind(jobName, length(phy[[3]]), nrepSim, TreeYears, epsilonProportion, epsilonMultiplier, nStepsPRC, numParticles, standardDevFactor)
	
time3<-proc.time()[[3]]
genTimes<-c(time.per.gen, time3)
prcResults<-vector("list")
prcResults$input.data<-input.data
prcResults$PriorMatrix<-PriorMatrix
prcResults$particleDataFrame<-particleDataFrame
prcResults$toleranceVector<-toleranceVector
prcResults$phy<-phy
prcResults$traits<-traits
prcResults$simTime<-simTime
prcResults$time.per.gen<-genTimes
prcResults$whichVip<-whichVip
prcResults$CredInt <-CredInt(particleDataFrame)
prcResults$HPD <-HPD(particleDataFrame)

#set number of cores back to 1	
registerDoMC(1) #DJG# this might need an if statement, windows won't be able to load DoMC 
print(prcResults)
}
	#------------------ ABC-PRC (end) ------------------
