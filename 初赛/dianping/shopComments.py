import requests
from bs4 import BeautifulSoup
import pandas as pd
import re
import genHeader        # 用于生成http请求头信息
import random
import time

# 爬取一页，返回html字符串
def getHtml(url, header=None):
    try:
        r = requests.get(url, headers=header)
        r.raise_for_status()
        r.encoding = r.apparent_encoding
        return r.text
    except Exception:
        print("--Error", r.status_code, "exception", Exception)

# 处理一页，返回值0为正常，1为终止逻辑，-1为错误
def soup1Page(html, fileName):
    try:
        soup = BeautifulSoup(html, features="html.parser")
        if soup.select(".no-review-item"):      # page超出最大页数
            print("Reviews out of range")
            return 1
        tags = soup("div", class_="main-review")        # 所有评论标签
        df = pd.DataFrame(columns=["时间", "评分", "口味", "环境", "服务", "人均"])
        idx = 0
        for tag in tags:
            row = []
            txt = tag.select('.time')[0].get_text()     # 创建时间
            row.append(txt.strip())
            p = tag.select('.review-rank')[0].span      # 所有评分
            row.append(re.findall("\d+\.?\d*", p['class'][1])[0])
            p = p.next_sibling.next_sibling.span        # 口味评分
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
            df.loc[idx] = row
            idx += 1
        df.to_csv(fileName, mode='a', index=False, header=False, sep=',', encoding='UTF-8')
        print("Write page", page, "successfully")
        if int(df.iat[len(df) - 1, 0][-14:-12]) < 18:   # 18年以前的数据不要
            return 1
        return 0
    except Exception:
        print("--Fail at page", page, ':', Exception)
        return -1


START_PAGE = 20
END_PAGE = 45
SHOPID = 'l4qpYSC2GYmz02SF'
FILENAME = "ltt_wangjing.csv"
failure = 0
for page in range(START_PAGE, END_PAGE):
    url = "http://www.dianping.com/shop/" + SHOPID + "/review_all/p{}?queryType=sortType&&queryVal=latest".format(page)
    header = genHeader.genHd(page)
    html = getHtml(url, header)   
    status = soup1Page(html, FILENAME)
    if status == 1:
        break
    elif status == -1:
        failure += 1
        print("Failure", failure)
        if failure >= 3:
            break
    time.sleep(random.randint(2, 6))
