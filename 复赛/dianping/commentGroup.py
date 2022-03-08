import pandas as pd

shopID = 6914402029330761728
fileName = "raw_" + str(shopID) + ".csv"
outName = "点评日评论数据.csv"
df = pd.read_csv(fileName, header=None)
df.columns = ["日期", "评分", "口味", "环境", "服务", "人均"]
df['日期'] = df['日期'].apply(lambda x: x[:10])
df = df.groupby('日期').agg({'评分': ['count', 'mean'], '口味': 'mean', '环境': 'mean', '服务': 'mean'})
df.columns = ['点评数', '评分', '口味', '环境', '服务']
if max(df.点评数) < 5:
    print("Too few comments: maximum only " + str(max(df.点评数)))
else:
    df['shopID'] = [shopID] * len(df)
    df.to_csv(outName, mode='a', index=True, header=False, sep=',', encoding='UTF-8')
    print("Write " + str(shopID) + " successfully: " + str(len(df)) + " rows")
