header = {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
        'Accept-Encoding': 'gzip, deflate',
        'Accept-Language': 'zh-CN,zh;q=0.9',
        'Cache-Control': 'max-age=0',
        'Connection': 'keep-alive',
        'Cookie': 'aburl=1; cy=2; cye=beijing; _lxsdk_cuid=178636e616bbd-06cf2b626f949c-5771031-144000-178636e616c2e; _lxsdk=178636e616bbd-06cf2b626f949c-5771031-144000-178636e616c2e; _hc.v=c0c030d4-d7c5-4d18-e744-158aae270cdc.1616575882; s_ViewType=10; cityid=2; default_ab=shop%3AA%3A11; UM_distinctid=178a7da97d82de-0e567be7ec3b8c-c3f3568-144000-178a7da97d9379; ctu=bde77ad8ea935a20646d9bebd6c78afa7f3b951c406815bfa99a4d788b75a547; ua=%E5%91%A8%E8%87%AA%E6%A8%AA; ll=7fd06e815b796be3df069dec7836c3df; Hm_lvt_602b80cf8079ae6591966cc70a3940e7=1617633569,1617760408,1617964561,1618243091; fspop=test; _lx_utm=utm_source%3DBaidu%26utm_medium%3Dorganic; thirdtoken=4ba8afee-4058-4da7-a865-1a90d2204d73; ctu=d3bbe533fc4ce8a33c2aa77e2258ae154f73add2c60d4648a7c708ac1262e88556f3952e93d49642d64fe147169172ac; dplet=06e95893a1a523e4ea27c1e3e3d1ece8; dper=1f90d3d6d689ab2215c818750a5bfa1a73b245f150cbcb0954444b924e0b435a8ed7d3e372d80ac8e8fc6dec0cd27eba6b360144c8eb55d4d0ee3013168829ab3fa8085bfd4e1512f954136e1ee2f11753024600bd53a346345bce20188b3ded;',
        'Host': 'www.dianping.com',
        'Upgrade-Insecure-Requests': '1',
        'User-Agent': ''
}
userAgent = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.114 Safari/537.36',
    'Mozilla/5.0 (Windows; U; Windows NT 6.1; en-us) AppleWebKit/534.50 (KHTML, like Gecko) Version/5.1 Safari/534.50',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.114 Safari/537.36 Edg/89.0.774.75'
]
# 手动登录时每次Cookie都会变，但只变最后两个参数，用一个list储存变的部分
# Cookie会过期，爬一段时间要手动修改list内容
cookie = [
    'Hm_lpvt_602b80cf8079ae6591966cc70a3940e7=1618393904; _lxsdk_s=178cfbcfd97-86c-ab3-d73%7C%7C1246',
    'Hm_lpvt_602b80cf8079ae6591966cc70a3940e7=1618394056; _lxsdk_s=178cfbcfd97-86c-ab3-d73%7C%7C1344',
    'Hm_lpvt_602b80cf8079ae6591966cc70a3940e7=1618394178; _lxsdk_s=178cfbcfd97-86c-ab3-d73%7C%7C1442'
]

# 每爬10页换一次User-Agent和Cookie
def genHd(page):
    hd = header
    use = page//10 % 3
    hd['User-Agent'] = userAgent[use]
    hd['Cookie'] += cookie[use]
    return hd
