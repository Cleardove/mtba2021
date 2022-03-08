import requests
from bs4 import BeautifulSoup
import pandas as pd
import re
import 复赛.dianping.genHeader as genHeader      # 用于生成http请求头信息
import random
import time


def getHtml(url, header=None):
    try:
        r = requests.get(url, headers=header)
        r.raise_for_status()
        r.encoding = r.apparent_encoding
        # print(r.text)
        return r.text
    except Exception:
        print("--Error", r.status_code, "exception", str(Exception))


def soup1Page(html, fileName):
    try:
        soup = BeautifulSoup(html, features="html.parser")
        if soup.select(".no-review-item"):      # page超出最大页数
            print("--Reviews out of range")
            return 1
        tags = soup("div", class_="main-review")        # 所有评论标签
        df = pd.DataFrame(columns=["时间", "评分", "口味", "环境", "服务", "人均"])
        idx = 0
        for tag in tags:
            row = []
            txt = tag.select('.time')[0].get_text()     # 创建时间
            row.append(txt.strip()[-16:])
            p = tag.select('.review-rank')[0].span      # 所有评分
            row.append(re.findall("\d+\.?\d*", p['class'][1])[0])
            p = p.next_sibling.next_sibling
            if p:
                p = p.span                                  # 口味评分
                row.append(re.findall("\d+\.?\d*", p.get_text())[0])
                p = p.next_sibling.next_sibling             # 环境评分
                row.append(re.findall("\d+\.?\d*", p.get_text())[0])
                p = p.next_sibling.next_sibling             # 服务评分
                row.append(re.findall("\d+\.?\d*", p.get_text())[0])
                p = p.next_sibling.next_sibling             # 人均消费，不一定有
                if p:
                    row.append(re.findall("\d+\.?\d*", p.get_text())[0])
                else:
                    row.append(None)
            else:
                row = row + [None] * 4
            df.loc[idx] = row
            idx += 1
        df.to_csv(fileName, mode='a', index=False, header=False, sep=',', encoding='UTF-8')
        print("Write page", page, "successfully at", df.iat[len(df) - 1, 0])
        if (int(df.iat[len(df) - 1, 0][:4]) <= 2020) & (int(df.iat[len(df) - 1, 0][5:7]) < 7):   # 20年7月以前的数据不要
            print("--Date too early")
            return 1
        return 0
    except Exception as e:
        print("--Fail at page", page, ':', str(e))
        return -1


DC = {6914402029330761728: 'G4ovNK3IOdQbKoRH',
      6601168278444312583: 'H614uOoEwvJDxT5F', 6601143789132187655: 'H4QF2I9Zk9pS4VIb', 6896223650630862848: 'l7dOqoLmHFmS3voI',
      6914775359254693899: 'l3YPrPQVR0rH8Yel', 6601125821002287112: 'G1n4EbtMWqCQrx4S', 6673736076571478028: 'j5DGZqcW1K2RXOG3'}

START_PAGE = 64
END_PAGE = START_PAGE + 60
SHOPID = 6914402029330761728
dianpingID = DC[SHOPID]
# dianpingID = "H34CMBWQApm6pggG"
FILENAME = "raw_" + str(SHOPID) + ".csv"
failure = []
for page in range(START_PAGE, END_PAGE):
    url = "http://www.dianping.com/shop/" + dianpingID + "/review_all/p{}?queryType=sortType&&queryVal=latest".format(page)
    header = genHeader.genHd(page)
    html = getHtml(url, header)
    status = soup1Page(html, FILENAME)
    if status == 1:
        break
    elif status == -1:
        print(url)
        failure.append(url)
        if len(failure) >= 2:
            break
    time.sleep(random.randint(4, 9))
for fail in failure:
    print(fail)
