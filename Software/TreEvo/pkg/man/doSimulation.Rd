\name{doSimulation}
\alias{doSimulation}

\title{Discrete Time Character Simulation}

\description{This function evolves continuous characters in a discrete time process.}

\usage{
doSimulation(splits, intrinsicFn, extrinsicFn, startingValues, intrinsicValues, extrinsicValues, timeStep, saveHistory=FALSE, saveRealParams=FALSE, jobName="")
}

\arguments{
  \item{splits}{Output from the function getSimulationSplits; is a data frame of branching times, ancestor and descendant vectors}
  \item{intrinsicFn}{Name of intrinsic function characters should be simulated under}
  \item{extrinsicFn}{Name of extrinsic function characters should be simulated under}
  \item{startingValues}{State at the root}
  \item{intrinsicValues}{Vector of values corresponding to the params of the intrinsic model}
  \item{extrinsicValues}{Vector of values corresponding to the params of the extrinsic model}
  \item{timeStep}{This value corresponds to the number of discrete time steps on the shortest branch}
  \item{saveHistory}{Saves the character history throughout the simulation}
  \item{saveRealParams}{Saves intrinsicValues and extrinsicValues as both a matrix and a vector}
  \item{jobName}{Optional name for the job}
}
\details{
	When saveHistory is TRUE, processor time will increase quite a bit.  SaveRealParams is useful for tracking the "real" true values if simulating data for abc runs.  It is not useful for empirical abc runs.  
}
\value{
	A data frame of species character (tip) values in the tree.
	}
\references{O'Meara and Banbury, unpublished}
\author{Brian O'Meara and Barb Banbury}

\examples{

phy<-rcoal(30)

#Simple Brownian motion
char<-doSimulation(
	splits=getSimulationSplits(phy), 
	intrinsicFn=brownianIntrinsic,
	extrinsicFn=nullExtrinsic,
	startingValues=c(10), #root state
	intrinsicValues=c(0.01),
	extrinsicValues=c(0),
	timeStep=0.0001,
	saveHistory=FALSE)


#Character displacement model with minimum bound
char<-doSimulation(
	splits=getSimulationSplits(phy), 
	intrinsicFn=boundaryMinIntrinsic,
	extrinsicFn=ExponentiallyDecayingPush,
	startingValues=c(10), #root state
	intrinsicValues=c(0.05, 10, 0.01),
	extrinsicValues=c(0, .1, .25),
	timeStep=0.001,
	saveHistory=FALSE)
}

\keyword{doSimulation}

