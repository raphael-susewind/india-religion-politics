library(seg)
library(rgdal)
library(spgrass6)

segregation <- function (city) {
 shapefile <- readOGR(".", city, verbose = FALSE)
 data <- cbind(shapefile@data$a_muslim*shapefile@data$a_electors/100, (100-shapefile@data$a_muslim)*shapefile@data$a_electors/100)
 colnames(data) <- c("Muslim","Non-Muslim")
 share <- as.data.frame(rbind(sum(shapefile@data$a_muslim*shapefile@data$a_electors/100)/sum(shapefile@data$a_electors)))
 colnames(share) <- c("muslim%")
 combined <- cbind(share,dissim(shapefile,data,adjust=TRUE))
 rownames(combined) <- c(city)
 execGRASS("g.remove", vect="tmp")
 return(combined)
}

write.table(rbind(segregation("ahmedabad"),segregation("ahmedabadcity"),segregation("aligarh"),segregation("aligarhcity"),segregation("bangalore"),segregation("bangalorecity"),segregation("bhopal"),segregation("bhopalcity"),segregation("calicut"),segregation("calicutcity"),segregation("cuttack"),segregation("cuttackcity"),segregation("delhi"),segregation("delhistate"),segregation("hyderabad"),segregation("hyderabadcity"),segregation("jaipur"),segregation("jaipurcity"),segregation("lucknow"),segregation("lucknowcity"),segregation("mumbai"),segregation("mumbaicity")), file="epa2017-results.csv",quote=FALSE,sep=", ",dec=".",row.names=TRUE,col.names=TRUE,na="")

