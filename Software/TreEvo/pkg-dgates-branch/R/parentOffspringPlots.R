parentOffspringPlots<-function(particleDataFrame){

x<-particleDataFrame
nparams<-dim(x)[2]-6
nb<-2*nparams
nf<-layout(matrix(1:nb, nrow=2, byrow=TRUE), respect=TRUE)
layout.show(nf)

for (param in 1:nparams) {
	param.position<-param+6
			
	plot(x[,param.position], x$generation, xlab=colnames(x)[param.position], ylab="Generation", type="n")
	title("size as measure of distance")
	kept<-subset(x[which(x$id>0),])[,]	
	reject<-subset(x[which(x$id<0),])[,]
	short.kept<-subset(kept[which(kept$generation>1),])[,]

	for (i in 1:nrow(reject)) {
		circle.size<-(reject[i, 5]/max(reject[,5]))*(0.05*(max(x[,param.position])-min(x[,param.position])))
		symbols(x=reject[i, param.position], y=reject[i, 1], circles=circle.size, inches=FALSE, add=TRUE, fg="gray")
	}	
	
	for (j in 1:nrow(kept)) {
		#circle.size<-(kept[j, 5]/max(kept[,5]))*mean(x[,param.position])
		circle.size<-(kept[j, 5]/max(kept[,5]))*(0.05*(max(kept[,param.position])-min(kept[,param.position])))
		symbols(x=kept[j, param.position], y=kept[j, 1], circles=circle.size, inches=FALSE, add=TRUE, fg="black")
	}		
	for (k in 1:nrow(short.kept)) {
		prev.gen<-subset(kept[which(kept$generation==short.kept[k, 1]-1),])[,]  #works to retreive prev gen
		lines(c(short.kept[k, param.position], prev.gen[short.kept[k,]$parentid, param.position]), c(short.kept[k, 1], short.kept[k, 1]-1))
	}	
}		
	
	
##-----For particle weights

for (param in 1:nparams) {
	param.position<-param+6

	plot(x[,param.position], x$generation, xlab=colnames(x)[param.position], ylab="Generation", type="n")
	title("size as measure of particle weights")
	kept<-subset(x[which(x$id>0),])[,]	
	reject<-subset(x[which(x$id<0),])[,]
	short.kept<-subset(kept[which(kept$generation>1),])[,]

	for (i in 1:nrow(reject)) {
		points(x=reject[i, param.position], y=reject[i, 1], col="gray", pch=8)

	}	
	
	for (j in 1:nrow(kept)) {
		circle.size<-(kept[j, 6]/max(kept[,6]))*(0.05*(max(kept[,param.position])-min(kept[,param.position])))
		symbols(x=kept[j, param.position], y=kept[j, 1], circles=circle.size, inches=FALSE, add=TRUE, fg="black")
	}		
	for (k in 1:nrow(short.kept)) {
		prev.gen<-subset(kept[which(kept$generation==short.kept[k, 1]-1),])[,]  #works to retreive prev gen
		lines(c(short.kept[k, param.position], prev.gen[short.kept[k,]$parentid, param.position]), c(short.kept[k, 1], short.kept[k, 1]-1))
	}	
}	

}		
