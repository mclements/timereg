
data(prt)
dim(prt)
table(prt$status)
### 21000 7000 1000

library(mets)
###
set.seed(100)
prt<-simnordic(7500,cordz=3,cormz=4,cratemz=0.1,cratedz=0.1)
prt$status <-prt$cause
table(prt$status)

prt<-simnordic(75000,cordz=2.0,cormz=3.,pcensmz=0.0,pcensdz=0.0,cratemz=200.4,cratedz=100.4)
prt$status <-prt$cause
table(prt$status)
prt$cancer <- (prt$status==1)

prt<-simnordic(7500,cordz=1,cormz=3,pcensmz=0.9,pcensdz=0.9,cratemz=0.9,cratedz=0.9)
prt$status <-prt$cause
prop.table(table(prt$status))


prt<-simnordic(75000,cordz=2.0,cormz=3.,pcensmz=0.0,pcensdz=0.0,cratemz=200.4,cratedz=100.4)
prt$status <-prt$cause
table(prt$status)
prt$cancer <- (prt$status==1)
###
bp3 <- bptwin(cancer~1,zyg="zyg",DZ="DZ",id="id",type="ace",data=prt)
summary(bp3)

coef(bp3)
exp(-0.1)/( exp(-0.1)+exp(-0.77)+1)
exp(-0.77)/( exp(-0.1)+exp(-0.77)+1)

gem <- c()
for (pcens in seq(0,0.95,length=5))
{
prt<-simnordic(7500,cordz=3,cormz=4,pcensmz=pcens,pcensdz=pcens,cratemz=0.5,cratedz=0.5)
prt$status <-prt$cause
tt <- table(prt$status)
if (length(tt)==2) tt <- c(0,tt)
prt$cancer <- (prt$status==1)
###
bp3 <- bptwin(cancer~1,zyg="zyg",DZ="DZ",id="id",type="ace",data=prt)
summary(bp3)
###
gem <- rbind(gem,c(pcens,tt,coef(bp3)))
}
gem


gemmzdz <- c()
concmz <- concdz <- marg <- cens <- gemmzdzc <- matrix(0,5,5)
cens <- gemmzdzc <- matrix(0,5,5)
gemmzdza <- matrix(0,5,5)
j <- i <- 0 
for (pcensmz in seq(0,0.95,length=5))
{
i <- i+1
j <- 0
for (pcensdz in seq(0,0.95,length=5))
{
j <- j+1
prt<-simnordic(100000,cordz=1.5,cormz=3,pcensmz=pcensmz,pcensdz=pcensdz,cratemz=0.9,cratedz=0.9)
prt$status <-prt$cause
tt <- table(prt$status)
if (length(tt)==2) tt <- c(0,tt)
prt$cancer <- (prt$status==1)
###
bp3 <- bptwin(cancer~1,zyg="zyg",DZ="DZ",id="id",type="ace",data=prt)
ud <- summary(bp3)
###
gemmzdz <- rbind(gemmzdz,c(pcensmz,pcensdz,tt,coef(bp3)))
print(c(i,j))
gemmzdza[i,j] <- coef(bp3)[2]
gemmzdzc[i,j] <- coef(bp3)[3]
marg[i,j] <- ud$probMZ[3,1]
concmz[i,j] <- ud$probMZ[1,1]
concdz[i,j] <- ud$probDZ[1,1]
cens[i,j] <- tt[1]/sum(tt)
}
}
###
gemmzdz
gemmzdza
gemmzdzc
###
h <- exp(gemmzdza)/(exp(gemmzdza)+exp(gemmzdzc)+1)
c <- exp(gemmzdzc)/(exp(gemmzdza)+exp(gemmzdzc)+1)
###
round(h,2)
round(c,2)
round(cens,2)
###
###h2.3 <- h 
###c2.3 <- c

h15.3 <- h 
c15.3 <- c

round(h1.3,2)
round(c1.3,2)

round(h2.3,2)
round(c2.3,2)

save(h1.3,file="h13.rda"); save(c1.3,file="c13.rda")
save(h2.3,file="h23.rda"); save(c2.3,file="c23.rda")
save(concmz,file="concMZ23.rda"); save(marg,file="marg23.rda")

table(prt$zyg,prt$status)

library(latextable)
cbind(h1.3,c1.3)

########################################################################################
#####################   MC
########################################################################################
library(doMC)
library(mets)
registerDoMC()

onerun <- function(k)
{#{{{
print(k)
pcensmz  <- seq(0,0.95,length=5)
j <- (k%%5)
j[j==0] <- 5
i <-ceiling(k/5)
print(c(i,j))
prt<-simnordic(10000,cordz=1.5,cormz=3,pcensmz=pcensmz[i],pcensdz=pcensmz[j],cratemz=0.2,cratedz=0.2)
prt$status <-prt$cause
tt <- table(prt$status)
if (length(tt)==2) tt <- c(0,tt)
prt$cancer <- (prt$status==1)
###
bp3 <- bptwin(cancer~1,zyg="zyg",DZ="DZ",id="id",type="ace",data=prt)
ud <- summary(bp3)
###
return(list(status=tt,pcensmz=pcensmz[i],pcensdz=pcensmz[j],bp3=bp3))
}#}}}
ud <- onerun(4)
prop.table(ud$status)

res <- c()
res <- foreach (i=1:25) %dopar% onerun(i)

gemmzdz <- c()
concmz <- concdz <- marg <- cens <- gemmzdzc <- matrix(0,5,5)
cens <- gemmzdzc <- matrix(0,5,5)
gemmzdza <- matrix(0,5,5)
for (k in 1:length(res)) {
j <- (k%%5)
j[j==0] <- 5
i <-ceiling(k/5)
print(c(i,j))
print(c(res$pcensmz,res$pcensdz)); 
bp3 <- res[[k]]$bp3
gemmzdza[i,j] <- coef(bp3)[2]
gemmzdzc[i,j] <- coef(bp3)[3]
marg[i,j] <- ud$probMZ[3,1]
concmz[i,j] <- ud$probMZ[1,1]
concdz[i,j] <- ud$probDZ[1,1]
tt <- res[[k]]$status
cens[i,j] <- tt[1]/sum(tt)
}
cens
h <- exp(gemmzdza)/(exp(gemmzdza)+exp(gemmzdzc)+1)
c <- exp(gemmzdzc)/(exp(gemmzdza)+exp(gemmzdzc)+1)
###
round(h,2)
round(c,2)
round(cens,2)
#

