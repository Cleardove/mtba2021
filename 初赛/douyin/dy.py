import json
import os
import time
import pandas as pd


def timeFormat(timestamp):
    return time.strftime("%Y-%m-%d %H:%M", time.localtime(timestamp))


def writeJsonData(js, sheetName):
    df = pd.DataFrame(columns=["时间", "点赞数", "回复数", "标签"])
    idx = 0
    for cmt in js['comments']:
        row = [timeFormat(cmt['create_time']), cmt['digg_count'], cmt['reply_comment_total'], cmt['label_type']]
        df.loc[idx] = row
        idx += 1
    df.to_csv(sheetName, mode='a', index=False, header=False, sep=',', encoding='UTF-8')


VEDIONAME = "201002@大LOGO吃垮北京L45.4wC2.2wS9124"
fileRoot = "./" + VEDIONAME + "/"
sheetName = VEDIONAME + ".csv"
for root, dirs, files in os.walk(fileRoot):
    for fileName in files:
        with open(os.path.join(root, fileName), 'r', encoding='UTF-8') as f:
            js = json.loads(f.readline())
            writeJsonData(js, sheetName)
    # break
