\name{autoregressiveIntrinsic}
\alias{autoregressiveIntrinsic}

\title{Intrinsic Character Evolution Models}

\description{This function describes a model of intrinsic character evolution. New character values are generated after one time step via a discrete-time OU process.}

\usage{
autoregressiveIntrinsic(params,states, timefrompresent)
}

\arguments{
  \item{params}{describes input paramaters for the model. \code{autoregressiveIntrinsic} params = sd (sigma), attractor (character mean), attraction (alpha)}   
  \item{states}{vector of states for each taxon}
  \item{timefrompresent}{which time slice in the tree}
}
\details{
}
\value{
	A matrix of values representing character displacement from a single time step in the tree.
	}
\references{O'Meara and Banbury, unpublished}
\author{Brian O'Meara and Barb Banbury}
\seealso{
}
\examples{

}
\keyword{}

