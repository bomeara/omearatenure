\name{MinBoundaryAutoregressiveIntrinsic}
\alias{MinBoundaryAutoregressiveIntrinsic}

\title{Intrinsic Character Evolution Models}

\description{This function describes a model of intrinsic character evolution. New character values are generated after one time step via a discrete-time OU process with a minimum bound.}

\usage{
MinBoundaryAutoregressiveIntrinsic(params,states, timefrompresent)
}

\arguments{
  \item{params}{describes input paramaters for the model. \code{MinBoundaryAutoregressiveIntrinsic} params = sd (sigma), attractor (character mean), attraction (alpha), minimum}   
  \item{states}{vector of states for each taxon}
  \item{timefrompresent}{which time slice in the tree}
}

\value{
	A matrix of values representing character displacement from a single time step in the tree.
}

\references{O'Meara and Banbury, unpublished}
\author{Brian O'Meara and Barb Banbury}

\keyword{MinBoundaryAutoregressiveIntrinsic}
\keyword{intrinsic}

