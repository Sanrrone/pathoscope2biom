#####TUTORIAL######
#PATHOSCOPE -> BIOM

library(phyloseq)
library(taxize)
library(plyr)
library(dplyr)
library(biomformat)


args <-commandArgs()

directory<-args[6]
pattr<-args[7]
olpwd<-getwd()

#define functions to fetch lineage
uid2lineage<-function(x){
  
  #define the main error in case of the fetch fail
  tmp<-c("Error in FUN(X[[i]], ...) : Gateway Timeout (HTTP 504)")
  
  #define the number of retrys per id in case of fail
  retry<-10
  
  #adding one slice of security
  while (grepl("Gateway Timeout",tmp) && retry>0) {
    tryCatch({tmp<-classification(x, db = 'ncbi')}, error = function(e){
      print(e);print("retrying");tmp<-"Gateway Timeout"})
    retry=retry-1
  }
  
  #get the df that contain the lineage
  tmpdf<-as.data.frame(tmp[[1]])
  if(nrow(tmpdf)>1){
    superk<-ifelse(identical("character(0)",superk<-as.character(tmpdf[which(
      tmpdf[2]=="superkingdom"),][1])),"NA",superk)
    phylum<-ifelse(identical("character(0)",phylum<-as.character(tmpdf[which(
      tmpdf[2]=="phylum"),][1])),"NA",phylum)
    class<-ifelse(identical("character(0)",class<-as.character(tmpdf[which(
      tmpdf[2]=="class"),][1])),"NA",class)
    order<-ifelse(identical("character(0)",order<-as.character(tmpdf[which(
      tmpdf[2]=="order"),][1])),"NA",order)
    family<-ifelse(identical("character(0)",family<-as.character(tmpdf[which(
      tmpdf[2]=="family"),][1])),"NA",family)
    genus<-ifelse(identical("character(0)",genus<-as.character(tmpdf[which(
      tmpdf[2]=="genus"),][1])),"NA",genus)
    species<-ifelse(identical("character(0)",species<-as.character(tmpdf[which(
      tmpdf[2]=="species"),][1])),"NA",species)
    name<-as.character(tmpdf[nrow(tmpdf),][1])
    out<-data.frame(ID=x,Superkingdom=superk,Phylum=phylum,Class=class,
                    Order=order,Family=family,Genus=genus,Species=species,
                    `Last Rank`=name)
  }else{
    out<-data.frame(ID=x,Superkingdom="NA",Phylum="NA",Class="NA",
                    Order="NA",Family="NA",Genus="NA",Species="NA",
                    Last.Rank="NA") 
  }
  return(out)
  
}
dflineage<-function(x){
  print("fetching IDs, please be patient")
  out<-ldply(lapply(x,uid2lineage),data.frame)
  out[out=="NA"]<-NA
  return(out)
}

setwd(directory)

#read pathoscope output (make you sure that only there are pathoscope files)
files = list.files(pattern=pattr)
tsvs<-lapply(files, read.table, sep="\t",skip=1,header=T,stringsAsFactors = FALSE)

#the cols that we need are the first and fourth, so we construct a new table from that cols
tsvs<- lapply(tsvs, function(x){x[,c(1,4)]})

#change the name of the read numbers to file name
for(i in 1:length(tsvs)){
  colnames(tsvs[[i]])<-c("Genome",files[i])
}

#now we merge all data frames into one
merged<-tsvs %>% Reduce(function(dtf1,dtf2) full_join(dtf1,dtf2,by="Genome"), .)

#replace NA by 0 and then remove the cols that not have any read assigned
merged[is.na(merged)]<-0
merged<-merged[rowSums(merged[,c(2:ncol(merged))])>0,]

#now we have to delete the characters "ti|" of our first column (and move the taxID to rownames)
merged<-as.data.frame(sapply(merged, function(x) gsub("ti\\|", "", x)))
rownames(merged)<-merged[,1]
merged<-merged[,-1]

#finally convert our table, into a OTU table
OTU=otu_table(data.matrix(merged),taxa_are_rows = T)

#to obtain the TAX table, we use only the rownames of the OTU table

taxIDs<-rownames(OTU)

lineages<-dflineage(taxIDs)
rownames(lineages)<-lineages[,1]
lineages<-lineages[,-1]
#replace the rownames to avoid future match errors
taxa_names(lineages)<-rownames(lineages)

#and finally convert our data frame into TAX table
TAX=tax_table(as.matrix(lineages))

#make a biom object with our previous objects
biomob<-make_biom(data = OTU,observation_metadata = TAX)

#then write the bion file!
write_biom(biomob,paste(olpwd,"thebiom.biom",sep = "/"))

