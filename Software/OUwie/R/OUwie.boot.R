#Simple bootstrap function for assessing confidence in OUwie estimates

#written by Jeremy M. Beaulieu

OUwie.boot <- function(phy, data, model=c("BM1","BMS","OU1","OUM","OUMV","OUMA","OUMVA"), nboot=100, alpha, sigma.sq, theta, theta0, simmap.tree=FALSE, scaleHeight=FALSE, root.station=TRUE, clade=NULL, lb=0.000001, ub=1000, mserr="none", diagn=FALSE, quiet=TRUE, warn=FALSE){
	
	#the matrix we are building to store the results:
	res<-c()
	#if alpha is NA set to a really small number -- this is only relevant for BM models:
	alpha[is.na(alpha)]<-1e-10

	cat("Beginning parametric bootstrap -- performing", nboot, "replicates", "\n")
	
	for(i in 1:nboot){
		tmp.phy<-phy
		if(mserr=="known"){
			if(!dim(data)[2]==4){
				stop("You specified measurement error should be incorporated, but this information is missing")
			}else{
				#Now lengthen the terminal branches to reflect the intraspecific variation at the tips:
				terminals <- tmp.phy$edge[,2] <= Ntip(tmp.phy)
				terminal.edges <- tmp.phy$edge.length[terminals]
				tmp.phy$edge.length[terminals] <- terminal.edges + data[,4]
			}
		}
		#This calls the OUwie simulator and simulates datasets:
		tmp <- OUwie.sim(tmp.phy, data, simmap.tree=simmap.tree, scaleHeight=scaleHeight, alpha=alpha, sigma.sq=sigma.sq, theta=theta, theta0=theta0)
		#OUwie.sim outputs the trait file in the order of the tree, but the trait file is likely not to be this way. So I alphabetized the input trait file above, and I do the same to the simulated trait file:
		data <- data[order(data[,1]),]
		tmp <- tmp[order(tmp[,1]),]
		#Replaces the data column with the simulated data:
		data[,3] <- tmp[,3]
		#Now run OUwie, using the measurement error if it is contained within the data, to estimate the parameters from the simulated data:
		tmp <- OUwie(phy, data, model=model, simmap.tree=simmap.tree, scaleHeight=scaleHeight, root.station=root.station, lb=lb, ub=ub, clade=clade, mserr=mserr, diagn=diagn, quiet=quiet, warn=warn)
		#Now bind all the relevant output together
		res <- rbind(res, c(tmp$solution[1,], tmp$solution[2,], tmp$theta[,1]))
	}
	if(root.station==TRUE){
		theta.mat<-matrix(t(tmp$theta), 2, length(levels(tmp$tot.states)))
		rownames(theta.mat)<-c("estimate", "se")
		if(tmp$simmap.tree==FALSE){
			colnames(theta.mat)<- levels(tmp$tot.states)
		}
		if(tmp$simmap.tree==TRUE){
			colnames(theta.mat) <- c(colnames(tmp$phy$mapped.edge))
		}
		colnames(res) <- c(paste("alpha", levels(tmp$tot.states),sep="_"),paste("sigma.sq", levels(tmp$tot.states),sep="_"),paste("theta", colnames(theta.mat),sep="_"))
	}else{
		theta.mat<-matrix(t(tmp$theta), 2, length(levels(tmp$tot.states))+1)
		rownames(theta.mat)<-c("estimate", "se")
		if(tmp$simmap.tree==FALSE){
			colnames(theta.mat)<-c("root", levels(tmp$tot.states))
		}
		if(tmp$simmap.tree==TRUE){
			colnames(theta.mat)<-c("root", colnames(tmp$phy$mapped.edge))
		}
		colnames(res) <- c(paste("alpha", levels(tmp$tot.states),sep="_"),paste("sigma.sq", levels(tmp$tot.states),sep="_"),paste("theta", colnames(theta.mat),sep="_"))
	}
	class(res) <- "OUwie.boot"
	return(res)
}



