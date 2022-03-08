import pandas as pd

df = pd.read_csv("抖音视频信息.csv", encoding='UTF-8')
vdLs = df.店铺ID.to_list()
df = pd.read_csv("抖音店铺信息.csv", encoding='UTF-8')

for shop in df.店铺ID:
    if shop not in vdLs:
        print(shop)