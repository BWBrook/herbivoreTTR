# Explicit PDF renderer; sourcing this helper writes nothing.
plot_feeding_access_study <- function(result,path) {
  grDevices::pdf(path,width=12,height=8.5,onefile=TRUE)
  on.exit(grDevices::dev.off())
  par(mfrow=c(2,3),mar=c(4,4,3,1),oma=c(0,0,3,0))
  configs <- c("continuous","clustered","fragmented")
  for (config in configs) {
    s <- result$systems[[paste(config,1,"bounded",sep="_")]]
    plot(NA,xlim=c(0,100),ylim=c(0,100),asp=1,xlab="x (m)",ylab="y (m)",main=config)
    rect(s$cells$xmin_m,s$cells$ymin_m,s$cells$xmax_m,s$cells$ymax_m,
      col="#83B79A",border="#225F47")
    text(s$stations$x_m,s$stations$y_m,1:8,cex=.75)
    points(s$stations$x_m[1],s$stations$y_m[1],pch=1,cex=2,col="#1C4365",lwd=2)
  }
  for (n in c(1,2,4)) {
    plot(NA,xlim=c(-1,11),ylim=c(-1,11),asp=1,xlab="Within-block x (m)",
      ylab="Within-block y (m)",main=paste(n^2,"numerical cells per feeding block"))
    rect(0,0,10,10,col="#DCEBDD",border=NA)
    abline(v=seq(0,10,length.out=n+1),h=seq(0,10,length.out=n+1),col="#7D9785")
    rect(0,0,10,10,border="#225F47",lwd=3)
    points(5,5,pch=19,col="#1C4365")
    text(5,-.7,"Same station, footprint and 0.6 m²/h search",cex=.65)
  }
  mtext("Fixed physical feeding supports; numerical subdivision changes no habitat",outer=TRUE,cex=1.15)
  par(mfrow=c(2,3),oma=c(0,0,3,0))
  colors <- c(none="#236C5B",pulse="#B27B23",sustained="#A63D40")
  for (variable in c("body_energy_kj","accessible_mass_kg_dm")) for(config in configs) {
    d <- subset(result$design,role=="primary" & configuration==config)
    denom <- if(variable=="body_energy_kj") 1000 else 1
    ylim <- range(c(0,unlist(lapply(result$runs[d$id],function(r) r$daily[[variable]]/denom))))
    plot(NA,xlim=c(0,228),ylim=ylim,xlab="Day",ylab=if(denom==1000)
      "Body energy reserve (MJ)" else "Accessible forage (kg DM)",main=config)
    rect(60,par("usr")[3],144,par("usr")[4],col="#F2EEE7",border=NA)
    rect(60,par("usr")[3],88,par("usr")[4],col="#E4D9C6",border=NA)
    for(i in seq_len(nrow(d))) {
      r <- result$runs[[d$id[i]]]
      x <- r$daily
      lines(x$day,x[[variable]]/denom,col=colors[d$profile[i]],
        lty=if(d$water[i]=="near") 1 else 2,lwd=1.7)
      if(!is.na(r$stop_day)) points(tail(x$day,1),tail(x[[variable]],1)/denom,
        pch=4,col=colors[d$profile[i]])
    }
    if(config=="continuous" && variable=="body_energy_kj")
      legend("bottomleft",c("No growth reduction","28-day pulse","84-day reduction","Near water","Far water"),
        col=c(colors,"grey30","grey30"),lty=c(1,1,1,1,2),bty="n",cex=.7)
  }
  mtext("Experienced policy: growth disturbances, water access and recovery",outer=TRUE,cex=1.15)
  par(mfrow=c(2,3),oma=c(0,0,3,0))
  labels <- c("Experienced","Informed","Cyclic","Zero forage transit","Pooled search","Pooled stock")
  cols <- c("#222222","#326C9B","#B27B23","#72579C","#B7473A","#1C836D")
  for(variable in c("body_energy_kj","cumulative_forage_travel_h")) for(config in configs) {
    d <- subset(result$design,configuration==config & profile=="sustained" & water=="far" &
      role %in% c("primary","policy","access"))
    keys <- ifelse(d$access=="physical",d$policy,d$access)
    d <- d[match(c("experienced","informed","cyclic","zero_transit","pooled_search","pooled_stock"),keys),]
    series <- lapply(result$runs[d$id],function(r) {
      x <- r$daily
      if(variable=="body_energy_kj") data.frame(day=x$day,value=x$body_energy_kj/1000)
      else data.frame(day=x$day,value=cumsum(ifelse(x$day>60,x$forage_travel_h,0)))
    })
    ylim <- range(c(0,unlist(lapply(series,`[[`,"value"))))
    if(diff(ylim)==0) ylim <- c(0,1)
    plot(NA,xlim=c(60,228),ylim=ylim,xlab="Day",ylab=if(variable=="body_energy_kj")
      "Body energy reserve (MJ)" else "Forage travel since branching (h)",main=config)
    rect(60,par("usr")[3],144,par("usr")[4],col="#F2EEE7",border=NA)
    for(i in seq_along(series)) lines(series[[i]]$day,series[[i]]$value,
      col=cols[i],lty=if(i>=4) 2 else 1,lwd=1.7)
    if(variable=="body_energy_kj" && config=="continuous") legend("bottomleft",labels,
      col=cols,lty=c(1,1,1,2,2,2),bty="n",cex=.7)
  }
  mtext("Attribution controls: sustained growth reduction and far water, matched day-60 states",
    outer=TRUE,cex=1.1)
  invisible(path)
}

plot_feeding_access_followup <- function(main_result,followup,path) {
  grDevices::pdf(path,width=10,height=8)
  on.exit(grDevices::dev.off())
  par(mfrow=c(2,2),mar=c(4,4,3,1),oma=c(0,0,3,0))
  for(variable in c("body_energy_kj","accessible_mass_kg_dm")) for(w in c("near","far")) {
    ids <- with(main_result$design,which(role=="primary" & configuration=="continuous" &
      water==w & profile %in% c("none","pulse")))
    runs <- list(main_result$runs[[ids[1]]],followup$runs[[w]],main_result$runs[[ids[2]]])
    denom <- if(variable=="body_energy_kj") 1000 else 1
    plot(NA,xlim=c(60,228),ylim=range(c(0,unlist(lapply(runs,function(r) r$daily[[variable]]/denom)))),
      xlab="Day",ylab=if(denom==1000) "Body energy reserve (MJ)" else "Accessible forage (kg DM)",
      main=paste(w,"water"))
    rect(60,par("usr")[3],67,par("usr")[4],col="#E4D9C6",border=NA)
    for(i in seq_along(runs)) lines(runs[[i]]$daily$day,runs[[i]]$daily[[variable]]/denom,
      col=c("#236C5B","#326C9B","#A63D40")[i],lty=c(1,1,2)[i],lwd=1.7)
    if(w=="near" && variable=="body_energy_kj") legend("bottomleft",
      c("No growth reduction","7-day follow-up pulse","Original 28-day pulse"),
      col=c("#236C5B","#326C9B","#A63D40"),lty=c(1,1,2),bty="n",cex=.8)
  }
  mtext("Exploratory follow-up: short-term recovery can precede later reserve decline",outer=TRUE,cex=1.05)
  invisible(path)
}
