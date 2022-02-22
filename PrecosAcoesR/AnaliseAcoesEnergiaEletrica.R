install.packages("tseries")
install.packages("plyr")
install.packages("zoo")
install.packages("Quandl")
install.packages("tibble")
install.packages("openxlsx")

library(tseries)
library(plyr)
library(zoo)
library(Quandl)
library(tibble)
library(openxlsx)

#Download S&P Prices###################
tckk <- c("CMIG4.SA","ELET3.SA","ELET6.SA","ENBR3.SA","EGIE3.SA","EQTL3.SA","CPRE3.SA","ENEV3.SA","ELPL3.SA","LIGT3.SA") #ATRIBUINDO O CONJUNTO#
numtk <- length(tckk); #TAMANHO DO CONJUNTO#
ustart <- "2014-01-01"; #DATA INICIAL#
uend <- "2019-06-30" #DATA FINAL#
all_dat <- list(); #LISTA VAZIA PARA ARMAZENAR OS DADOS#
for(i in 1:numtk)
{
  all_dat[[i]] <- stock_prices <- get.hist.quote(instrument = tckk[i], #PREENCHENDO A LISTA VAZIA#
                                        start=ustart, 
                                        end=uend, 
                                        quote = c("Close"), 
                                        provider = "yahoo", 
                                        compression = "m")
}


#############Gráfico dos Preços ####################################

prices=matrix(NA,ncol=length(tckk),nrow=nrow(as.matrix(all_dat[[1]]))) #CRIANDO UMA MATRIZ VAZIA#

for(i in 1:length(tckk)){
  prices[,i] = all_dat[[i]]$Close
} #PREENCHENDO POR LOOP A MATRIZ

Dates=index(all_dat[[1]]$Close) #INDEXAR A DATA PARA PLOTAR#
ret=diff(log(prices))*100
colnames(ret)=tckk


######Gráfico dos  Retornos #########
for (i in 1:length(tckk)){
  plot(Dates,prices[,i],type="l",col="red",ylab = tckk[i],xlab = "Data")
  plot(Dates[2:length(Dates)],ret[,i],type="l",ylab = paste("retorno",tckk[i]),xlab = "Data")
}


################Calcular o retorno médio ########################


ret_medio <- apply(ret,2,FUN=mean)
print(ret_medio)


#############Calcular o desvio Padrão ###############################

desv_pad <- apply(ret,2,FUN=sd)
print(desv_pad)


###########Calcular o Sharpe ###########################################

sharpe <- ret_medio/desv_pad
print(sharpe)

####################Download Ibovespa ##########################################

##### A SEGUNDA PARTE DO TRABALHO COMEÇA AQUI#####

#Download S&P Prices###################
tckk_ibov <- c("^BVSP") #CRIAÇÃO DO CONJUNTO IBOV#
numtk <- length(tckk_ibov); #TAMANHO DO CONJUNTO#
ustart <- "2014-01-01"; #INÍCIO DO PERÍODO#
uend <- "2019-06-30" #FINAL DO PERÍODO#
all_dat_ibov <- list(); #CRIAÇÃO DA MATRIZ#
for(i in 1:numtk) #LOOP#
{
  all_dat_ibov[[i]] <- ibov <- get.hist.quote(instrument = tckk_ibov[i],
                                        start=ustart,
                                        end=uend,
                                        quote = c( "Close"),
                                        provider = "yahoo",
                                        compression = "m")
}


ibov <- all_dat_ibov[[1]]$Close


#################Calcular o Ibovespa ####################################
ret_ibov <- diff(log(ibov))*100
ret_medio_ibov <- mean(ret_ibov)
var_ibov = var(ret_ibov)
desv_pad_ibov = sqrt(var_ibov)
sharpe_ibov = ret_medio_ibov/desv_pad_ibov

Dates=index(all_dat[[1]]$Close) #NEM PRECISA PORQUE A DATA JÁ TÁ INDEXADA
i=1
plot(Dates,ibov,type="l",main="Ibovespa 2014-2019",col="blue",ylab = "Pontos",xlab = "Data") #GRÁFICO DO IBOV#

Dates_ret=index(ret_ibov) #ESSA PRECISA INDEXAR PORQUE O DATE DO RETORNO É DIFERENTE"
plot(Dates_ret,ret_ibov[,i],
     type="l",
     main="Retorno Ibovespa 2014-2019",
     col="red",
     ylab = "Retorno (%a.m.)",
     xlab = "Data") #GRÁFICO DO IBOV#

########### Calcular a matrix de variância covariância ######################

 asset.names <- tckk #ATRIBUINDO OS ATIVOS
 mu.vec = ret_medio/100 #RETORNO MÉDIO
 names(mu.vec) = asset.names #ATRIBUINDO RETORNO MÉDIO
 sigma.mat = cov(ret/100) #MATRIZ DE VARIÂNCIA E COVARIÂNCIA
 dimnames(sigma.mat) = list(asset.names, asset.names)
 print(mu.vec) #mostrar no console
 print(sigma.mat) #mostrar no console

 
 
 ############ Carteira 1 com pesos iguais #################
 
  x.vec = rep(1,length(tckk))/length(tckk) #proporção da carteira#
  names(x.vec) = asset.names #nomeando os ativos
  mu.p.x = crossprod(x.vec,mu.vec) #retorno médio da carteira#
  sig2.p.x = t(x.vec)%*%sigma.mat%*%x.vec #variância da carteira#
  sig.p.x = sqrt(sig2.p.x) #desvio padrão da carteira#
  sharpe_cart1 <- mu.p.x/sig.p.x #sharpe da carteira 1#
  print(mu.p.x*100)
  print(sig.p.x*100)
  print(sharpe_cart1)
  

######################## Carteira 2, modelos de Markowitz Minima variancia ###################
  
   top.mat = cbind(2*sigma.mat, rep(1, length(tckk)))
   bot.vec = c(rep(1, length(tckk)), 0)
   Am.mat = rbind(top.mat, bot.vec)
   b.vec = c(rep(0, length(tckk)), 1)
   z.m.mat = solve(Am.mat)%*%b.vec
  m.vec.2 = z.m.mat[1:length(tckk),1]
  print(m.vec.2) # PROPORÇÃO DA CARTEIRA = valores negativos = vender a descoberto#
  sum(m.vec.2) #deve ser igual a um
  
  #mesmo procedimento da carteira passada#
  x.vec.2 <- m.vec.2 #atribuindo os parâmetros de proporção da carteira#
  mu.p.x.2 = crossprod(x.vec.2,mu.vec)
  sig2.p.x.2 = t(x.vec.2)%*%sigma.mat%*%x.vec.2
  sig.p.x.2 = sqrt(sig2.p.x.2)
  sharpe_cart2 <- mu.p.x.2/sig.p.x.2
  print(mu.p.x.2*100)
  print(sig.p.x.2*100)
  print(sharpe_cart2)
  
  
  
################ Carteiras baseadas nos betas #########################################
  
################# Computando os betas ##############################################
  
betas <- matrix(NA, nrow = length(tckk),ncol = 1) #criando o beta
  
  for(i in 1:length(tckk)){ 
    reg <- lm(ret[,i] ~ ret_ibov) #relacionando os dois retornos (ibov e ações) para criação do beta
    summary(reg)
    betas[i,] <- round(reg$coefficients[2],2)
    } #loop dos betas
  
  betas_df <- tibble::tibble(Ativo = tckk, Beta = as.vector(betas)) 
  print(betas_df)
  
  ############# Quanto maior o beta maior o peso, carteira 3 ##############

  m.vec.3 <- numeric(length = length(tckk)) 
  
  for(i in 1:length(tckk)){ 
    m.vec.3[i] <- betas[i,]/sum(betas)
    }
  
  x.vec.3 <- m.vec.3
  mu.p.x.3 = crossprod(x.vec.3,mu.vec)
  names(x.vec.3) = asset.names #nomeando os ativos
  sig2.p.x.3 = t(x.vec.3)%*%sigma.mat%*%x.vec.3
  sig.p.x.3 = sqrt(sig2.p.x.3)
  sharpe_cart3 <- mu.p.x.3/sig.p.x.3
  print(mu.p.x.3*100)
  print(sig.p.x.3*100)
  print(sharpe_cart3)
  
  ################ Carteira 4, quanto menor o beta maior o peso #####################
  
  m.vec.4 <- numeric(length = length(tckk)) 
  
  for(i in 1:length(tckk)){ 
    m.vec.4[i] <- (1/betas[i,])/sum(1/betas)
  }
  
  
  
  x.vec.4 <- m.vec.4
  mu.p.x.4 = crossprod(x.vec.4,mu.vec)
  names(x.vec.4) = asset.names #nomeando os ativos
  sig2.p.x.4 = t(x.vec.4)%*%sigma.mat%*%x.vec.4
  sig.p.x.4 = sqrt(sig2.p.x.4)
  sharpe_cart4 <- mu.p.x.4/sig.p.x.4
  print(mu.p.x.4*100)
  print(sig.p.x.4*100)
  print(sharpe_cart4)
  
  #ATRIBUINDO CONJUNTO DOS SHARPES#
  SH <- c(sharpe_cart1,sharpe_cart2,sharpe_cart3,sharpe_cart4)
  sharpe_carts <- as.data.frame(t(SH))
  colnames(sharpe_carts) <- c("Carteira 1", "Carteira 2", "Carteira 3", "Carteira 4")
  print(sharpe_carts)
  
  #OBTENDO O GRÁFICO DAS PROPORÇÕES DAS CARTEIRAS#
  pesos <- cbind(x.vec,x.vec.2,x.vec.3,x.vec.4)
  pesos <- round(pesos,4)
  pesos_df <- as.data.frame(pesos)
  colnames(pesos_df) <- c("Carteira 1", "Carteira 2", "Carteira 3", "Carteira 4")
  print(pesos_df)
  plot(pesos_df)
  
  #OBTENDO OS RETORNOS DAS CARTEIRAS#
  retorno_carts  <- cbind(mu.p.x,mu.p.x.2,mu.p.x.3,mu.p.x.4)
  retorno_carts <- round(retorno_carts*100,4)
  retorno_carts <- as.data.frame(retorno_carts)
  colnames(retorno_carts) <- c("Carteira 1", "Carteira 2", "Carteira 3", "Carteira 4")
  print(retorno_carts)
  
  #OBTENDO OS DESVIOS PADRÃO DAS CARTEIRAS#
  desv_pad_carts  <- cbind(sig.p.x,sig.p.x.2,sig.p.x.3,sig.p.x.4)
  desv_pad_carts <- round(desv_pad_carts*100,4)
  desv_pad_carts <- as.data.frame(desv_pad_carts)
  colnames(desv_pad_carts) <- c("carteira 1", "carteira 2", "carteira 3", "carteira 4")
  print(desv_pad_carts)
  