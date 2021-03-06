#intrinsic models
#note that these work for univariate, but need to be generalized for multivariate
#otherstates has one row per taxon, one column per state
#states is a vector for each taxon, with length=nchar

nullIntrinsic<-function(params,states, timefrompresent) {
	newdisplacement<-0*states
	return(newdisplacement)
}


brownianIntrinsic<-function(params,states, timefrompresent) {
	newdisplacement<-rnorm(n=length(states),mean=0,sd=params) #mean=0 because we ADD this to existing values
	return(newdisplacement)
}


boundaryIntrinsic<-function(params, states, timefrompresent) {
	#params[1] is sd, params[2] is min, params[3] is max. params[2] could be 0 or -Inf, for example
	newdisplacement<-rnorm(n=length(states),mean=0,sd=params[1])
	for (i in length(newdisplacement)) {
		newstate<-newdisplacement[i]+states[i]
		if (newstate<params[2]) { #newstate less than min
			newdisplacement[i]<-params[2]-states[i] #so, rather than go below the minimum, this moves the new state to the minimum
		}
		if (newstate>params[3]) { #newstate greater than max
			newdisplacement[i]<-params[3]-states[i] #so, rather than go above the maximum, this moves the new state to the maximum
		}
	}
	return(newdisplacement)
}


boundaryMinIntrinsic <-function(params, states, timefrompresent) {
	#params[1] is sd, params[2] is min boundary
	newdisplacement<-rnorm(n=length(states),mean=0,sd=params[1])
	for (i in length(newdisplacement)) {
		newstate<-newdisplacement[i]+states[i]
		if (newstate<params[2]) { #newstate less than min
			newdisplacement[i]<-params[2]-states[i] #so, rather than go below the minimum, this moves the new state to the minimum
		}
	}
	return(newdisplacement)
}


autoregressiveIntrinsic<-function(params,states, timefrompresent) { #a discrete time OU, same sd, mean, and attraction for all chars
	#params[1] is sd (sigma), params[2] is attractor (ie. character mean), params[3] is attraction (ie. alpha)
	sd<-params[1] 
	attractor<-params[2] 
	attraction<-params[3]	#in this model, this should be between zero and one
	newdisplacement<-rnorm(n=length(states),mean=(attractor-states)*attraction,sd=sd) #subtract current states because we want displacement
	return(newdisplacement)
	
} 


MinBoundaryAutoregressiveIntrinsic<-function(params,states, timefrompresent) { #a discrete time OU, same sd, mean, and attraction for all chars
	#params[1] is sd (sigma), params[2] is attractor (ie. character mean), params[3] is attraction (ie. alpha), params[4] is min bound
	sd<-params[1] 
	attractor<-params[2] 
	attraction<-params[3]	#in this model, this should be between zero and one
	minBound<-params[4]
	newdisplacement<-rnorm(n=length(states),mean=(attractor-states)*attraction,sd=sd) #subtract current states because we want displacement
	#print(newdisplacement)
	for (i in length(newdisplacement)) {
		newstate<-newdisplacement[i] + states[i]
		#print(newstate)
			if (newstate <params[4]) { #newstate less than min
				newdisplacement[i]<-params[4] - states[i] #so, rather than go below the minimum, this moves the new state to the minimum
			}
	}
	return(newdisplacement)
	
}


autoregressiveIntrinsicTimeSlices<-function(params,states, timefrompresent) { #a discrete time OU, differing mean, sigma, and attaction with time
	#params=[sd1, attractor1, attraction1, timethreshold1, sd2, attractor2, attraction2, timethreshold2, ...]
	#time is time before present (i.e., 65 could be 65 MYA). The last time threshold should be 0, one before that is the end of the previous epoch, etc.
	numRegimes<-length(params)/4
	timeSliceVector=c(Inf,params[which(c(1:length(params))%%4==0)])
	#print(timeSliceVector)
	sd<-params[1]
	attractor<-params[2]
	attraction<-params[3]	#in this model, this should be between zero and one
	#print(paste("timefrompresent = ",timefrompresent))
	for (regime in 1:numRegimes) {
		#print(paste ("tryiing regime = ",regime))
		if (timefrompresent<timeSliceVector[regime]) {
			#print("timefrompresent>timeSliceVector[regime] == TRUE")
			if (timefrompresent>=timeSliceVector[regime+1]) {
				#print("timefrompresent<=timeSliceVector[regime+1] == TRUE")
				#print(paste("choose regime ",regime, " so 4*(regime-1)=",4*(regime-1)))
				sd<-params[1+4*(regime-1)]
				attractor<-params[2+4*(regime-1)]
				attraction<-params[3+4*(regime-1)]
					#print(paste("sd = ",sd," attractor = ",attractor, " attraction = ", attraction))

			}	
		}	
	}
	#print(paste("sd = ",sd," attractor = ",attractor, " attraction = ", attraction))
	newdisplacement<-rnorm(n=length(states),mean=(attractor-states)*attraction,sd=sd)
	return(newdisplacement)
}

autoregressiveIntrinsicTimeSlicesConstantMean<-function(params,states, timefrompresent) { #a discrete time OU, constant mean, differing sigma, and differing attaction with time
	#params=[sd1 (sigma1), attraction1 (alpha 1), timethreshold1, sd2 (sigma2), attraction2 (alpha 2), timethreshold2, ..., attractor (mean)]
	#time is time before present (i.e., 65 could be 65 MYA). The last time threshold should be 0, one before that is the end of the previous epoch, etc.
	numTimeSlices<-(length(params)-1)/3
	sd<-params[1]
	attractor<-params[length(params)]
	attraction<-params[2]	#in this model, this should be between zero and one
	previousThresholdTime<-Inf
	for (slice in 0:(numTimeSlices-1)) {
		thresholdTime<-params[3+3*slice]
		if (thresholdTime >= timefrompresent) {
			if (thresholdTime<previousThresholdTime) {
				sd<-params[1+3*slice]
				attraction<-params[2+3*slice]
			}		
		}	
		previousThresholdTime<-thresholdTime
	}
	newdisplacement<-rnorm(n=length(states),mean=attraction*states + attractor,sd=sd)-states
	return(newdisplacement)
}

autoregressiveIntrinsicTimeSlicesConstantSigma<-function(params,states, timefrompresent) { #a discrete time OU, differing mean, constant sigma, and attaction with time
	#params=[sd, attractor1, attraction1, timethreshold1, attractor2, attraction2, timethreshold2, ...]
	#time is time before present (i.e., 65 could be 65 MYA). The last time threshold should be 0, one before that is the end of the previous epoch, etc.
	numRegimes<-(length(params)-1)/3
	#print(numRegimes)
	timeSliceVector<-c(Inf)
	for (regime in 1:numRegimes) {
		timeSliceVector<-append(timeSliceVector,params[4+3*(regime-1)])
	}
	#timeSliceVector=c(Inf,params[which(c(1:length(params))%%4==0)])
	#print(timeSliceVector)
	sd<-params[1]
	attractor<-params[2]
	attraction<-params[3]	#in this model, this should be between zero and one
	#print(paste("timefrompresent = ",timefrompresent))
	for (regime in 1:numRegimes) {
		#print(paste ("trying regime = ",regime))
		if (timefrompresent<timeSliceVector[regime]) {
			#print("timefrompresent>timeSliceVector[regime] == TRUE")
			if (timefrompresent>=timeSliceVector[regime+1]) {
				#print("timefrompresent>=timeSliceVector[regime+1] == TRUE")
				#print(paste("chose regime ",regime))
				#sd<-params[1+4*(regime-1)]
				attractor<-params[2+3*(regime-1)]
				attraction<-params[3+3*(regime-1)]
				#print(paste("sd = ",sd," attractor = ",attractor, " attraction = ", attraction))

			}	
		}	
	}
	#print(paste("sd = ",sd," attractor = ",attractor, " attraction = ", attraction))
	newdisplacement<-rnorm(n=length(states),mean=(attractor-states)*attraction,sd=sd)
	return(newdisplacement)
}
