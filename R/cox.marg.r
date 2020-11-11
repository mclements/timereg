
#' @export
cox.marg <- function(survformula,glmformula,d=parent.frame(),max.clust=NULL,ipw.se=FALSE,tie.seed=100)
{ ## {{{ 
  ggl <- glm(glmformula,family='binomial',data=d)
  mat <-  model.matrix(glmformula,data=d);
  glmcovs <- attr(ggl$terms,"term.labels")
  ppp <-predict(ggl,type="response")
  ppp[ggl$y==0] <- 1- ppp[ggl$y==0]
  d$ppp <- ppp

###  dcc <- na.omit(d)
  ## {{{ checking and breaking ties
  ties <- FALSE
  survtimes <- all.vars(update(survformula,.~0))
  if (length(survtimes)==2) {itime <- 1; time2 <- d[,survtimes[1]]; status <- d[,survtimes[2]]; }
  if (length(survtimes)==3) {itime <- 2;  time2 <- d[,survtimes[2]]; status <- d[,survtimes[3]]; }
  jtimes <- time2[status==1]; 
  dupli <- duplicated(jtimes)
  if (sum(dupli)>0) {
	  set.seed(tie.seed)
	  jtimes[dupli] <- jtimes[dupli]+runif(sum(dupli))*0.01
	  time2[status==1] <- jtimes
	  d[,survtimes[itime]] <- time2
	  ties <- TRUE
  }
  ## }}}

###  dcc <- d[ggl$y==1,]
  dcc <- d
  ppp <- dcc$ppp
###  print(head(1/ppp))

  timeregformula <- timereg.formula(survformula)
  udcox <- coxph(survformula,data=dcc,weights=1/ppp)  
  udca <- cox.aalen(timeregformula,data=dcc,weights=1/ppp,n.sim=0,max.clust=max.clust)  
###  print(summary(udca))

  ### iid of beta for Cox model 
  coxiid <- udca$gamma.iid

if (ipw.se==TRUE)  { ## {{{ 
###requireNamespace("lava"); requireNamespace("NumDeriv"); 
glmiid <-   lava::iid(ggl)
###mat <- mat
par <- coef(ggl)

coxalpha <- function(par)
{ ## {{{ 
  rr <- mat %*% par
  pw <- c(exp(rr)/(1+exp(rr)))
  pw[ggl$y==0] <- 1 - pw[ggl$y==0]
  assign("pw",pw,envir=environment(survformula))
###  if (coxph==FALSE) 
  ud <- cox.aalen(timeregformula,data=dcc,weights=1/pw,beta=udca$gamma,Nit=1,n.sim=0,robust=0)  
###  else { ud <- coxph(survformula,data=dcc,weights=1/pw,iter.max=1,init=udca$gamma)  
###	 ud <- coxph.detail(ud,data=dcc)
###  }
  ud$score
} ## }}} 

DU <-  numDeriv::jacobian(coxalpha,par,)
IDU <-  udca$D2linv %*% DU 
alphaiid <-t( IDU %*% t(glmiid))
###
iidfull <- alphaiid
###
iidfull <- coxiid + alphaiid
###
var2 <- t(iidfull) %*% iidfull
se <- cbind(diag(var2)^.5); colnames(se) <- "se"
} else { iidfull <- NULL; var2 <- NULL; se <- NULL} ## }}} 

se.naive=coef(udca)[,3,drop=FALSE]; colnames(se.naive) <- "se.naive"

res <- list(iid=iidfull,coef=udca$gamma,var=var2,se=se,se.naive=se.naive,ties=list(ties=ties,time2=time2,cox=udca))
class(res) <- "cox.marg"
return(res)
} ## }}} 

#' @export
summary.cox.marg <- function(object,digits=3,...)
{
	tval <- object$coef/object$se
	pval <- 2*(1-pnorm(abs(tval)))
       	res <- cbind(object$coef,object$se,object$se.naive,pval)
	colnames(res) <- c("coef","se","se.naive","pval")

return(res)
}

#' @export
coef.cox.marg<- function(object,digits=3,...)
{
summary.cox.marg(object)
}

#' @export
print.cox.marg  <-  function(x,...)
{ 
summary.cox.marg(x)
}

