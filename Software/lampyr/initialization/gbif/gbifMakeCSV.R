#install.packages('dismo')
library(dismo)
#Good dataresourcekey
good<-c(
674 ,#Arizona state herp collection
675 ,#Arizona state lichen collection
676 ,#Arizona state vascular plant
977 ,#Herps in Alaska
973 ,#birds at UNM
980 ,#mammals at UNM
988 ,#fish at UNM
972 ,#mammals at UNM
985 ,#museum southwestern biology
11617 ,#DMNS birds
7911 ,#kansas entomology
7914 ,#kansas lichen
7915 ,#kansas vascular plants
995 ,#kansas fish
982 ,#kansas herps
13717 ,#ohio state fish
7984 #LSU herbarium
)
#wicked good
wickedgood<-c(
581 ,#mcz mammals
580 ,#mcz birds
579 ,#MCZ fish
158 ,#antweb
177 ,#field museum mammals
8967 ,#NYBG herbarium
625 ,#ohio state insects
12031 ,#MCZ herps
1066 #USDA plant db
)

paleoDB<-563 #paleodb



allgood<-c(paleoDB,good,wickedgood)

convertData<-function(dataresourcekey) {
	load(file=paste("gbif_dataresource_",dataresourcekey,'.Rsave',sep=""))
	subdata<-cbind(data$species,data$lat,data$lon)
	write.table(subdata,file=paste("gbif_dataresource_",dataresourcekey,".csv",sep=""),col.names=FALSE,quote=FALSE,row.names=FALSE,sep=",")
	rm(data)
}

for (goodIndex in sequence(length(allgood))) {
	try(convertData(allgood[goodIndex])) 
}
