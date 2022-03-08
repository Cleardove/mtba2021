header = {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
        'Accept-Encoding': 'gzip, deflate',
        'Accept-Language': 'zh-CN,zh;q=0.9',
        'Cache-Control': 'max-age=0',
        'Connection': 'keep-alive',
        'Cookie': '__mta=250918841.1619790301828.1619790301828.1619790301828.1; aburl=1; cy=2; cye=beijing; _lxsdk_cuid=178636e616bbd-06cf2b626f949c-5771031-144000-178636e616c2e; _lxsdk=178636e616bbd-06cf2b626f949c-5771031-144000-178636e616c2e; _hc.v=c0c030d4-d7c5-4d18-e744-158aae270cdc.1616575882; s_ViewType=10; cityid=2; default_ab=shop%3AA%3A11; UM_distinctid=178a7da97d82de-0e567be7ec3b8c-c3f3568-144000-178a7da97d9379; ctu=bde77ad8ea935a20646d9bebd6c78afa7f3b951c406815bfa99a4d788b75a547; fspop=test; ctu=d3bbe533fc4ce8a33c2aa77e2258ae151ad4b48398e84e1ea4f02283fae0eb6e33eb43275ec12474c1cfa4fac7d48be8; thirdtoken=8b44b66e-a749-485f-bb87-797aa6d5cce5; Hm_lvt_602b80cf8079ae6591966cc70a3940e7=1619502627,1619766854,1619841523,1619845878; _dp.ac.v=c0733603-60e0-41f3-809a-16f02b4592f4; dplet=b577655c87ea45c2780522366dcb8727; dper=222e18884e4ffd8b7f73808ad3dfaae43f3f9a5ee2acf2fec1345f57eb0c32effce0e8a7f8092c7a38c27a1b6d93e7b6cbebc4286d646a2ae0b992b5c2abc4a421c1288b01449c5d053f321fd4e550db781c95ef69b37fbe8a96ad5a286d655b; ll=7fd06e815b796be3df069dec7836c3df; ua=cool_1906; ',
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
    'Hm_lpvt_602b80cf8079ae6591966cc70a3940e7=1620097851; _lxsdk_s=17935384b3c-eac-4f4-918%7C%7C156;',
    'Hm_lpvt_602b80cf8079ae6591966cc70a3940e7=1620097858; _lxsdk_s=17935384b3c-eac-4f4-918%7C%7C263;',
    'Hm_lpvt_602b80cf8079ae6591966cc70a3940e7=1620097894; _lxsdk_s=17935384b3c-eac-4f4-918%7C%7C370;'
]


# 每爬10页换一次User-Agent和Cookie
def genHd(page):
    hd = header
    use = page//10 % 3
    hd['User-Agent'] = userAgent[use]
    hd['Cookie'] += cookie[use]
    return hd
