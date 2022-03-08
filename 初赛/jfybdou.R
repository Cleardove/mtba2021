library(dplyr)
library(ggplot2)
library(forecast)
library(vars)
library(MASS)
library(lmtest)
library(stargazer)
library(car)

## Data Reading
ori.wangjing <- read.csv("./dianping/jfyb_wangjing.csv", header = F, sep = ',')
colnames(ori.wangjing) <- c("date", "score", "flavor", "envir", "service", "price")
ori.wangjing$date %>% substr(1,10) %>% as.Date() -> ori.wangjing$date
startDate.wangjing = min(ori.wangjing$date)
ori.wangjing$week <- floor((as.numeric(ori.wangjing$date) - as.numeric(startDate.wangjing))/7)*7 + startDate.wangjing
daily.wangjing <- ori.wangjing %>% group_by(date) %>% 
  summarise(count = n(), score=mean(score), flavor=mean(flavor), envir=mean(envir), service=mean(service), price=mean(price))
weekly.wangjing <- ori.wangjing %>% group_by(week) %>% 
  summarise(count = n(), score=mean(score), flavor=mean(flavor), envir=mean(envir), service=mean(service), price=mean(price))
  
ori.oumeihui <- read.csv("./dianping/jfyb_oumeihui.csv", header = F, sep = ',')
colnames(ori.oumeihui) <- c("date", "score", "flavor", "envir", "service", "price")
ori.oumeihui$date %>% substr(1,10) %>% as.Date() -> ori.oumeihui$date
startDate.oumeihui = min(ori.oumeihui$date)
ori.oumeihui$week <- floor((as.numeric(ori.oumeihui$date) - as.numeric(startDate.oumeihui))/7)*7 + startDate.oumeihui
daily.oumeihui <- ori.oumeihui %>% group_by(date) %>% 
  summarise(count = n(), score=mean(score), flavor=mean(flavor), envir=mean(envir), service=mean(service), price=mean(price))
weekly.oumeihui <- ori.oumeihui %>% group_by(week) %>% 
  summarise(count = n(), score=mean(score), flavor=mean(flavor), envir=mean(envir), service=mean(service), price=mean(price))

ori.dou <- read.csv("./douyin/201002@大LOGO吃垮北京L45.4wC2.2wS9124.csv", header = F, sep = ',')
colnames(ori.dou) <- c("date", "like", "reply", "label")
ori.dou$date %>% substr(1,10) %>% as.Date() -> ori.dou$date
startDate.dou = min(ori.dou$date)
ori.dou$week <- floor((as.numeric(ori.dou$date) - as.numeric(startDate.dou))/7)*7 + startDate.dou
daily.dou <- ori.dou %>% group_by(date) %>% summarise(count = n())
weekly.dou <- ori.dou %>% group_by(week) %>% summarise(count = n())

startDate.dou %>% weekdays()
ori.dou$week2 <- floor((as.numeric(ori.dou$date) - as.numeric(startDate.dou))/7)*7 + startDate.dou + 3
ori.dou$week2[which(ori.dou$date <= '2020-10-04')] = '2020-09-28'
weekly.dou2 <- ori.dou %>% group_by(week2) %>% summarise(count = n())
colnames(weekly.dou2)[1] <- "week"

ori.ctrl.wangjing <- read.csv("./dianping/ltt_wangjing.csv", header = F, sep = ',')
colnames(ori.ctrl.wangjing) <- c("date", "score", "flavor", "envir", "service", "price")
ori.ctrl.wangjing$date %>% substr(1,10) %>% as.Date() -> ori.ctrl.wangjing$date
ori.ctrl.wangjing <- ori.ctrl.wangjing[which(ori.ctrl.wangjing$date >= '2020-08-19'),]
daily.ctrl.wangjing <- ori.ctrl.wangjing %>% group_by(date) %>% summarise(count = n())
ori.ctrl.wangjing$week <- floor((as.numeric(ori.ctrl.wangjing$date) - as.numeric(min(ori.ctrl.wangjing$date)))/7)*7 + min(ori.ctrl.wangjing$date)
weekly.ctrl.wangjing <- ori.ctrl.wangjing %>% group_by(week) %>% summarise(count = n())


## Plotting
ggplot() + geom_line(data=daily.wangjing, aes(x=date, y=count))
ggplot(data=daily.wangjing, aes(x=date, y=count)) + geom_point() + geom_smooth(se=F)
ggplot(cbind('count' = (daily.wangjing$count %>% ts() %>% ma(7)), 'date' = daily.wangjing$date) %>% data.frame()) +
  geom_line(aes(x=as.Date(date), y=count)) + scale_x_date(date_breaks = "3 week", date_labels = "%m-%d") +
  xlab("日期") + ylab("评论数")
ggplot() + geom_line(data=weekly.wangjing, aes(x=week, y=count))

ggplot() + geom_line(data=daily.oumeihui[750:1033,], aes(x=date, y=count))
ggplot(cbind('count' = (daily.oumeihui[750:1033,]$count %>% ts() %>% ma(7)), 'date' = daily.oumeihui[750:1033,]$date) %>% data.frame()) +
  geom_line(aes(x=as.Date(date), y=count))
ggplot() + geom_line(data=weekly.oumeihui[110:153,], aes(x=week, y=count))

ggplot(data=daily.ctrl.wangjing, aes(x=date, y=count)) + geom_point() + geom_smooth(se=F)
ggplot(cbind('count' = (daily.ctrl.wangjing$count %>% ts() %>% ma(7)), 'date' = daily.ctrl.wangjing$date) %>% data.frame()) +
  geom_line(aes(x=as.Date(date), y=count))
ggplot() + geom_line(data=weekly.ctrl.wangjing, aes(x=week, y=count))

ggplot() + geom_line(data=daily.dou, aes(x=date, y=log(count+1))) +
  scale_x_date(date_breaks = "3 week", date_labels = "%m-%d") +
  xlab("日期") + ylab("log(评论数)")
ggplot() + geom_line(data=weekly.dou, aes(x=week, y=log(count+1)))


plot.ts((weekly.wangjing-weekly.oumeihui[123:153,])$count)

## Regression
dat.wj <- left_join(daily.wangjing, daily.dou, by="date")
colnames(dat.wj)[2] <- "comments"
colnames(dat.wj)[8] <- "dou"
dat.wj$dou[which(is.na(dat.wj$dou))] = 0
attach(dat.wj)

summary(m1 <- lm(logCmt ~ logDou, data=dat.vec))
m1$residuals %>% ur.df() %>% summary()

dat.vec <- data.frame(cbind(BoxCox(comments, BoxCox.lambda(comments)), BoxCox(dou, BoxCox.lambda(dou))))
colnames(dat.vec) <- c("logCmt", "logDou")
# dat.vec = dat.vec * 100
VARselect(dat.vec, lag.max = 14)
dat.vec %>% VAR(p=3, type = "const") -> m2
m2 %>% summary()
causality(m2, cause = "logDou")$Granger

VARselect(dat.wj[,c(2,8)], lag.max = 14)
dat.wj[,c(2,8)] %>% VAR(p=9, type = "const") -> m3
# VARselect(cbind(diff(dat.wj$comments), diff(dat.wj$dou)), lag.max = 14)
# cbind('comments' = diff(dat.wj$comments), 'dou' = diff(dat.wj$dou)) %>% VAR(p=2, type = "const") -> m3
m3 %>% summary()
causality(m3, cause = "dou")$Granger
serial.test(m3, lags.pt = 10)

dat.lags <- cbind(comments = comments[18:210], douLag0 = dou[18:210],
                  douLag1 = dou[17:209], douLag2 = dou[16:208],
                  douLag3 = dou[15:207], douLag4 = dou[14:206],
                  douLag5 = dou[13:205], douLag6 = dou[12:204],
                  douLag7 = dou[11:203], douLag8 = dou[10:202],
                  douLag9 = dou[9:201], douLag10 = dou[8:200],
                  douLag11 = dou[7:199], douLag12 = dou[6:198],
                  douLag13 = dou[5:197], douLag14 = dou[4:196],
                  douLag15 = dou[3:195], douLag16 = dou[2:194],
                  douLag17 = dou[1:193]) %>% data.frame()
summary(m4 <- glm(comments ~ ., family = "quasipoisson", data = dat.lags))
summary(m5 <- lm(comments ~ ., data = dat.lags))
dev.res = rstandard(m4)
plot(dev.res ~ m4$fitted)
plot(m4, which=c(2))
plot(m4, which=c(4))
plot(m4$residuals)
acf(m4$residuals)

m6 <- auto.arima(comments[18:210], xreg = as.matrix(dat.lags[,2:9]))
summary(m6)
acf(m6$residuals)
pacf(m6$residuals)
m7 <- auto.arima(log(comments[18:210]+1), xreg = as.matrix(log(dat.lags[,2:9]+1)))
summary(m7)
acf(m7$residuals)

## Weekly
dat.week <- left_join(weekly.wangjing, weekly.dou2, by="week")
colnames(dat.week)[2] <- "comments"
colnames(dat.week)[8] <- "dou"
dat.week$dou[which(is.na(dat.week$dou))] = 0
attach(dat.week)
dat.week.lag <- cbind(comments = comments[3:31], douLag0 = dou[3:31],
                  douLag1 = dou[2:30], douLag2= dou[1:29]) %>% data.frame()
dat.week.lag[,2:4] = log(dat.week.lag[,2:4] + 1)
summary(m9 <- glm(comments ~ ., family = "quasipoisson", data = dat.week.lag))
dat.week.lag <- cbind(comments = comments[2:31], douLag0 = dou[2:31],
                      douLag1 = dou[1:30]) %>% data.frame()
dat.week.lag[,2:3] = log(dat.week.lag[,2:3] + 1)
summary(m8 <- glm(comments ~ ., family = "quasipoisson", data = dat.week.lag[2:30,]))
stargazer(m9, m8, type = "html")
1-pchisq(m8$deviance, m8$df.residual)
ncvTest(m8)
dev.res = rstandard(m8)
plot(dev.res ~ m8$fitted)
plot(m8, which=c(2))
plot(m8, which=c(4))
plot(m8$residuals)
acf(m8$residuals)

VARselect(dat.week[,c(2,8)], lag.max = 14)
dat.week[,c(2,8)] %>% VAR(p=2, type = "const") -> m10
# VARselect(cbind(diff(dat.wj$comments), diff(dat.wj$dou)), lag.max = 14)
# cbind('comments' = diff(dat.wj$comments), 'dou' = diff(dat.wj$dou)) %>% VAR(p=2, type = "const") -> m3
m10 %>% summary()
causality(m10, cause = "dou")$Granger
serial.test(m10, lags.pt = 10)

mean(ori.wangjing$price, na.rm = T)
mean(ori.oumeihui$price, na.rm = T)

## Oumeihui
dat.om <- left_join(daily.oumeihui, daily.dou, by="date")
colnames(dat.om)[2] <- "comments"
colnames(dat.om)[8] <- "dou"
dat.om$dou[which(is.na(dat.om$dou))] = 0
dat.om <- dat.om[824:1033,]
attach(dat.om)
datom.lags <- cbind(cmt = comments[18:210], douLag0 = dou[18:210],
                  douLag1 = dou[17:209], douLag2 = dou[16:208],
                  douLag3 = dou[15:207], douLag4 = dou[14:206],
                  douLag5 = dou[13:205], douLag6 = dou[12:204],
                  douLag7 = dou[11:203], douLag8 = dou[10:202],
                  douLag9 = dou[9:201], douLag10 = dou[8:200],
                  douLag11 = dou[7:199], douLag12 = dou[6:198],
                  douLag13 = dou[5:197], douLag14 = dou[4:196],
                  douLag15 = dou[3:195], douLag16 = dou[2:194],
                  douLag17 = dou[1:193]) %>% data.frame()
# dat.lags[,2:19] = log(dat.lags[,2:19] + 1)
summary(m6 <- glm(cmt ~ ., family = "quasipoisson", data = datom.lags))
summary(m7 <- lm(cmt ~ ., data = dat.lags))

cnt <- daily.wangjing[which(daily.wangjing$date >= '2020-10-12'),]
sum(cnt$count)
sum(is.na(ori.wangjing$price))
mean(ori.wangjing$price, na.rm = T)
