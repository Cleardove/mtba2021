library(readxl)
library(dplyr)
library(plm)
library(ggplot2)

dat.shop <- read_excel("shops.xlsx")
str(dat.shop)
dat.shop$收藏量 %>% as.numeric() -> dat.shop$收藏量
dat.shop$浏览量 %>% as.numeric() -> dat.shop$浏览量
dat.shop$热度 %>% as.numeric() -> dat.shop$热度
dat.shop$附近商家数 %>% as.numeric() -> dat.shop$附近商家数;

dat.ved <- read_excel("vedio.xlsx")
dat.ved <- inner_join(dat.ved,dat.shop[,1:2],by="店铺ID")
str(dat.ved)
dat.ved$创建时间 %>% as.Date() -> dat.ved$日期
dat.ved$点赞量 %>% as.numeric() -> dat.ved$点赞量
dat.ved$评论量 %>% as.numeric() -> dat.ved$评论量
dat.ved$转发量 %>% as.numeric() -> dat.ved$转发量
dat.ved$视频长度 %>% as.numeric() -> dat.ved$视频长度;

dat.cmt <- read.csv("comments.csv", header = F, numerals = "no.loss")
colnames(dat.cmt) <- c("日期", "日评论", "日评分", "日口味", "日环境", "日服务", "店铺ID")
str(dat.cmt)
dat.cmt$店铺ID %>% as.character() -> dat.cmt$店铺ID
dat.cmt$日期 %>% as.Date() -> dat.cmt$日期
dat.cmt$日评分 %>% as.character() %>% as.numeric() -> dat.cmt$日评分
dat.cmt$日口味 %>% as.character() %>% as.numeric() -> dat.cmt$日口味
dat.cmt$日服务 %>% as.character() %>% as.numeric() -> dat.cmt$日服务
dat.cmt$日环境 %>% as.character() %>% as.numeric() -> dat.cmt$日环境;


dat <- dat.cmt
dat <- dat[which((dat$日期 >= "2020-06-01") & (dat$日期 <= "2021-04-24")), ]
i = 1
while (1) {
  if (dat$店铺ID[i]==dat$店铺ID[i+1] && (dat$日期[i+1]-dat$日期[i]>1) ) {
    dat %>% add_row(日期=dat$日期[i]+1, 日评论=0, 店铺ID=dat$店铺ID[i], .after = i) -> dat
  }
  i = i+1
  if (i == nrow(dat))
    break;
}
dat <- dat[which(dat$日期 >= "2020-07-01"), ]
dat <- left_join(dat, dat.shop[, c(1, 5:11, 13, 15, 16, 18, 20, 23)], by="店铺ID")

str(dat)
which(dat$评价数 %>% is.na())
# dat1 <- left_join(dat, dat.ved[, c(1:2, 5:8, 18, 20)], by=c("店铺ID", "日期"))
dat1 <- dat
dat1$treat1 <- rep(0, nrow(dat1))
dat1$treat2 <- rep(0, nrow(dat1))
dat1$treat3 <- rep(0, nrow(dat1))
dat1$treat4 <- rep(0, nrow(dat1));
for (i in 1:nrow(dat1)) {
  for (j in 1:nrow(dat.ved)) {
    if (dat1$店铺ID[i]==dat.ved$店铺ID[j]) {
      datediff = dat1$日期[i] - dat.ved$日期[j];
      if (datediff >= 0) {
        treat = dat.ved$点赞量[j]/10000;
        if (datediff<7) {
          dat1$treat1[i] = dat1$treat1[i] + treat;
        } else if (datediff<14) {
          dat1$treat2[i] = dat1$treat2[i] + treat;
        } else if (datediff<21) {
          dat1$treat3[i] = dat1$treat3[i] + treat;
        } else if (datediff<28) {
          dat1$treat4[i] = dat1$treat4[i] + treat;
        }
      }
    }
  }
}

pdt <- pdata.frame(dat1, index = c("店铺ID", "日期"))
pdt$人均2 <- pdt$人均^2
pm <- plm(日评论 ~ (treat1 + treat2 + treat3 + treat4) + 
               附近商家数 + 人均 + 评分 + 收藏量 + 是否有团购 + 种类名称,
             pdt, effect = "twoways")
summary(pm)
vcov(pm)
# pm <- glm(日评论 ~ treat1 + treat2 + treat3 + treat4 + 
#                附近商家数 + 人均 + 评分 + 收藏量 + 是否有团购 + 种类名称 + 日期,
#           pdt, family = poisson)
# summary(pm)
# pm %>% cooks.distance() %>% plot()
plot(x=dat1$人均, y=dat1$日评论)


dat2 <- dat.cmt[which(dat.cmt$日期 >= "2020-07-01"), ] %>% group_by(日期) %>% 
  summarize(comments = sum(日评论), score = mean(日评分, na.rm=T))
plot.ts(dat2$comments)

dat2 <- dat.ved[which(dat.ved$点赞量 >= 10000), ]
for (i in unique(dat2$店铺ID)) {
  dati <- dat1[which(dat1$店铺ID==i), ]
  if (max(dati$日评论) < 10)
    next;
  plot.ts(dati$日评论)
  for (j in (dat2[which(dat2$店铺ID==i),]$日期 - as.Date(dati$日期[1]) + 1)) {
    lines(c(j,j), c(0,100), col="red")
  }
  Sys.sleep(2)
}
dat.shop[which(dat.shop$店铺ID=="6925911523390933004"),]


# Plotting
dat.ved$like <- ">2w赞"
dat.ved$like[which(dat.ved$点赞量<=20000)] <- "1W-2W赞"
dat.ved$like[which(dat.ved$点赞量<=10000)] <- "5K-1W赞"
dat.ved$like[which(dat.ved$点赞量<=5000)] <- "3K-5K赞"
dat.ved$like[which(dat.ved$点赞量<=3000)] <- "1K-3K赞"
dat.ved$like <- factor(dat.ved$like, levels=c(">2w赞","1W-2W赞","5K-1W赞","3K-5K赞","1K-3K赞"))


ggplot(data.frame(table(dat.shop$区域)), aes(x=reorder(Var1,-Freq), y=Freq)) + 
  geom_bar(stat="identity", fill = "#035099")
ggplot(data.frame(table(dat.shop$种类)), aes(x=reorder(Var1,-Freq), y=Freq)) + 
  geom_bar(stat="identity", fill = "#035099")

ggplot(dat.ved, aes(x=是否探官, fill=like)) + 
  geom_bar(stat="count", position="fill", width=0.5) +
  scale_fill_manual(values = c("#990000", "#cc0000", "#dd4400", "#cc6600", "#cc8833"))
ggplot(dat.ved, aes(x=日期)) + 
  geom_bar(stat="count", width=0.5) +
  scale_fill_manual(values = c("#990000", "#cc0000", "#dd4400", "#cc6600", "#cc8833"))

dat <- left_join(dat.shop[,1:1], dat.ved[,1:2], by="店铺ID")
data.frame(table(dat$店铺ID))$Freq %>% summary()
dat <- left_join(dat.shop[,1:1], dat.cmt[which(dat.cmt$日期>= "2020-07-01" & dat.cmt$日期<= "2021-05-01"),c(1,7)], by="店铺ID")
data.frame(table(dat$店铺ID))$Freq %>% summary()
data.frame(table(dat$店铺ID)) -> t
t[-210,]$Freq %>% summary()


s <- dat.shop
ggplot(s, aes(x=人均, fill=是否有团购)) + geom_histogram()
ggplot(s, aes(x=服务, fill=是否有团购)) + geom_histogram()
ggplot(s, aes(x=种类, fill=是否有团购)) + geom_bar()
