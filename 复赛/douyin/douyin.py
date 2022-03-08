import json
import os
import time
import pandas as pd


def timeFormat(timestamp):
    return time.strftime("%Y-%m-%d %H:%M", time.localtime(timestamp))


def jsonPoi(js, sheetName):
    df = pd.DataFrame(columns=["店铺ID", "店铺名称", "同类排名", "热度", "种类编码", "种类名称",
                               "收藏量", "浏览量", "附近商家数", "人均消费", "省份", "城市", "区域", "地址",
                               "经度", "维度", "是否有团购", "团购名称", "团购价格"])
    idx = 0
    for shop in js["rank_items"]:
        poi = shop["poi_info"]
        row = [poi["poi_id"], poi["poi_name"], shop["rank"], shop["rank_value"], poi["poi_backend_type"]["code"],
               poi["poi_backend_type"]["name"], poi["collect_count"], None, None, poi["cost"],
               poi["address_info"]["province"], poi["address_info"]["city"], poi["address_info"]["district"],
               poi["address_info"]["address"], poi["longitude"], poi["latitude"]]
        if "product_info" in shop:
            group = shop["product_info"]["groupon"]
            row = row + [1, group["name"], group["price"]]
        else:
            row = row + [0, None, None]

        df.loc[idx] = row
        idx += 1
    df.to_csv(sheetName, mode='a', index=False, header=False, sep=',', encoding='UTF-8')


def jsonPoi2(js, shopID, sheetName):
    df = pd.read_csv(sheetName, sep=',', encoding='UTF-8')
    idx = df[df.店铺ID == int(shopID)].index[0]
    df.loc[idx, '浏览量'] = js["poi_info"]["view_count"]
    df.loc[idx, '附近商家数'] = js["around_hot_poi_count"]
    df.to_csv(sheetName, mode='w', index=False, header=True, sep=',', encoding='UTF-8')


def jsonKeyUser(js, shopID, sheetName):
    if 'key_user_rate_info' not in js:
        return
    df = pd.DataFrame(columns=["店铺ID", "视频ID", "视频标题", "创建时间", "点赞量", "评论量", "转发量",
                               "视频长度", "下载地址1", "下载地址2", "下载地址3", "下载地址4",
                               "作者id", "作者昵称", "作者签名", "作者性别", "作者生日", "是否探官", "探店次数"])
    idx = 0
    for rate in js["key_user_rate_info"]["key_user_rate_list"]:
        aweme = rate["aweme"]
        author = aweme["author"]
        url = aweme["video"]["download_addr"]["url_list"]
        row = [shopID, aweme["aweme_id"], aweme["desc"], timeFormat(aweme["create_time"]),
               aweme["statistics"]["digg_count"],
               aweme["statistics"]["comment_count"], aweme["statistics"]["share_count"], aweme["video"]["duration"],
               url[0], url[1], url[-2], url[-1], author["unique_id"], author["nickname"],
               author["signature"].replace('\n', '\\n'),
               author["gender"], author["birthday"],
               1, rate["tags"][1]["name"]]
        df.loc[idx] = row
        idx += 1
    df.to_csv(sheetName, mode='a', index=False, header=False, sep=',', encoding='UTF-8')


def jsonAweme(js, shopID, sheetName):
    df = pd.DataFrame(columns=["店铺ID", "视频ID", "视频标题", "创建时间", "点赞量", "评论量", "转发量",
                               "视频长度", "下载地址1", "下载地址2", "下载地址3", "下载地址4",
                               "作者id", "作者昵称", "作者签名", "作者性别", "作者生日", "是否探官", "探店次数"])
    idx = 0
    for aweme in js["aweme_list"]:
        if int(aweme["statistics"]["digg_count"]) < 1000:
            continue
        create_time = timeFormat(aweme["create_time"])
        if int(create_time[0:4]) < 2020:
            continue
        author = aweme["author"]
        url = aweme["video"]["download_addr"]["url_list"]
        row = [shopID, aweme["aweme_id"], aweme["desc"], create_time, aweme["statistics"]["digg_count"],
               aweme["statistics"]["comment_count"], aweme["statistics"]["share_count"], aweme["video"]["duration"],
               url[0], url[1], url[-2], url[-1], author["unique_id"], author["nickname"],
               author["signature"].replace('\n', '\\n'),
               author["gender"], author["birthday"], 0, None]
        df.loc[idx] = row
        idx += 1
    df.to_csv(sheetName, mode='a', index=False, header=False, sep=',', encoding='UTF-8')


df = pd.DataFrame(columns=["店铺ID", "店铺名称", "同类排名", "热度", "种类编码", "种类名称",
                           "收藏量", "浏览量", "附近商家数", "人均消费", "省份", "城市", "区域", "地址",
                           "经度", "维度", "是否有团购", "团购名称", "团购价格"])
df.to_csv("抖音店铺信息.csv", mode='w', index=False, header=True, sep=',', encoding='UTF-8')
df = pd.DataFrame(columns=["店铺ID", "视频ID", "视频标题", "创建时间", "点赞量", "评论量", "转发量",
                           "视频长度", "下载地址1", "下载地址2", "下载地址3", "下载地址4",
                           "作者id", "作者昵称", "作者签名", "作者性别", "作者生日", "是否探官", "探店次数"])
df.to_csv("抖音视频信息.csv", mode='w', index=False, header=True, sep=',', encoding='UTF-8')
fileRoot = "./__已处理/"
for root, dirs, files in os.walk(fileRoot):
    for fileName in files:
        print(fileName)
        with open(os.path.join(root, fileName), 'r', encoding='UTF-8') as f:
            js = json.loads(f.readline())
            if "rank_items" in js:
                jsonPoi(js, "抖音店铺信息.csv")
            elif "poi_info" in js:
                shopID = js["poi_info"]["poi_id"]
                jsonPoi2(js, shopID, "抖音店铺信息.csv")
                jsonKeyUser(js, shopID, "抖音视频信息.csv")
            else:
                shopID = js["aweme_res"]["poi_info"]["poi_id"]
                jsonAweme(js, shopID, "抖音视频信息.csv")
