\name{plotPosteriors}
\alias{plotPosteriors}


\title{Plot posterior distributions}

\description{This function plots posterior distributions from the last generation of each free parameter}

\usage{plotPosteriors(particleDataFrame, PriorMatrix, realParam=FALSE, realParamValues=NA)}

\arguments{
  \item{particleDataFrame}{particleDataFrame from TreEvo results, can be a single data frame or a list of data frames}
  \item{PriorMatrix}{PriorMatrix from TreEvo results, can be a single matrix or a list of matrices}
  \item{realParam}{Plot line segments where real parameter values are known}
  \item{realParamValues}{Values for real paramters, include a value for each parameter (inlcuding fixed values)}
}
\details{
	If the particleDataFrame is a list of seperate TreEvo runs, posteriors will be layered over eachother to check for repeatability.  Grayscale of posteriors depends on total number of runs.  
	
	If the PriorMatrix is a list of matrices, only the first matrix will be plotted.  In other words, prior matrices MUST be identical for all runs.
	
	realParam and realParamValues should only be used with simulated data, where the true values are known.  
}
\value{
	Returns a plot for each free parameter.  
}

\references{O'Meara and Banbury, unpublished}
\author{Barb Banbury and Brian O'Meara}

\examples{
#data(Res)
#plotPosteriors(particleDataFrame=res$particleDataFrame, PriorMatrix=res$priorMatrix, realParam=FALSE, realParamValues=NA)
}

\keyword{plotPosteriors}

