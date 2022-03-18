clear all
cd /Users/luzhehao/Dropbox/美团商赛/复赛/
set scheme s1color
* 设定考察的样本区间
glo per_nweek = 6

* 1. 店铺信息
import excel "shops.xlsx", sheet("Sheet1") firstrow clear
gen group_purchaseMT = 1
replace group_purchaseMT = 0 if 团购数量 == 0
ren 种类 rest_cat
ren 人均 expense_pc
ren 连锁店 chain_rest
ren 收藏量 collection
ren 浏览量 pageview
ren 热度 heat
ren 附近商家数 npoi_around
ren 是否有团购 group_purchaseDY
replace chain_rest = 0 if mi(chain_rest)

renvars 评分 口味 环境 服务 / score_total score_taste score_envir score_serv
destring chain_rest collection pageview heat expense_pc npoi_around group_purchaseDY, replace

* 判断商店的核心卖点
foreach v of varlist score_total score_taste score_envir score_serv{
	egen std`v' = std(`v')
}
isid 店铺ID
tempfile shops_info
save "`shops_info'"

* 2. 探店视频发布时间信息
import excel "video.xlsx", sheet("Sheet1") firstrow clear
ren 作者性别 arthor_gender
ren 是否探官 tanguan
ren 作者id 作者ID
destring *量 视频长度 arthor_gender tanguan, replace

* 保留目前已有的店铺样本
merge m:1 店铺ID using "`shops_info'", keep(3) ///
	keepus(rest_cat *score* expense_pc heat chain_rest collection pageview npoi_around group_purchaseDY group_purchaseMT ) nogen
unique 店铺ID

gen date = substr(创建时间, 1, 10)
gen ymd = date(date, "YMD")
sort ymd
format ymd %tdCCYY-NN-DD
gen vdur = 22400 - ymd
gen vlength = 视频长度/1000
gen loglike = log(点赞量)
gen logcomment = log(评论量+1)
gen logforward = log(转发量+1)
gen lognpoi_around = log(npoi_around+1)
gen logexpense_pc = log(expense_pc+1)
gen logcollection = log(collection+1)
gen rate_collectionDY = collection/pageview

drop 视频标题 创建时间 视频长度 下载* 评论量 转发量 作者生日 作者签名 探店次数

keep if inrange(ymd,22097, .) // 保留 2020.7.1 以后发布的视频

* Add Value Labels
cap drop like_cat
gen like_cat = 1 if inrange(点赞量,1000,3000)
replace like_cat = 2 if inrange(点赞量,3000,5000)
replace like_cat = 3 if inrange(点赞量,5000,10000)
replace like_cat = 4 if inrange(点赞量,10000,20000)
replace like_cat = 5 if inrange(点赞量,20000,.)
label define like_cat   1 "1K-3K赞" 2 "3K-5K赞" 3 "5K-1W赞" 4 "1W-2W赞" 5 ">2W赞" 
label value like_cat like_cat

cap drop style
gen style = 1 if rest_cat == "日料" 
replace style = 2 if rest_cat == "韩国料理" | rest_cat == "东南亚菜" 
replace style = 3 if rest_cat == "火锅"
replace style = 4 if rest_cat == "自助餐"
replace style = 5 if rest_cat == "小吃快餐" | rest_cat == "烧烤"
replace style = 6 if rest_cat == "北京菜"
replace style = 7 if rest_cat == "川菜"
replace style = 8 if rest_cat == "东北菜" | rest_cat == "本帮江浙菜" | rest_cat == "云贵菜" |  ///
					 rest_cat == "西北菜" | rest_cat == "湘菜" | rest_cat == "粤菜" | ///
					 rest_cat == "徽菜" 
label define style  1 "日料" 2 "韩料/东南亚菜" 3 "火锅" 4 "自助餐" 5 "快餐小吃烧烤" 6 "北京菜" 7 "川菜" 8 "其他非本地菜"
label value style style

cap drop vlength_cat
gen vlength_cat = 1 if inrange(vlength,0,15)
replace vlength_cat = 2 if inrange(vlength,15,30)
replace vlength_cat = 3 if inrange(vlength,30,60)
replace vlength_cat = 4 if inrange(vlength,60,120)
replace vlength_cat = 5 if inrange(vlength,120,.)
label define vlength_cat   1 "0-15秒" 2 "15-30秒" 3 "30-60秒" 4 "60-120秒" 5 "120秒以上" 
label value vlength_cat vlength_cat

cap drop expense_pc_cat
gen expense_pc_cat = 1 if inrange(expense_pc,0,50)
replace expense_pc_cat = 2 if inrange(expense_pc,50,100)
replace expense_pc_cat = 3 if inrange(expense_pc,100,200)
replace expense_pc_cat = 4 if inrange(expense_pc,200,300)
replace expense_pc_cat = 5 if inrange(expense_pc,300,.)
label define expense_pc_cat   1 "人均0-50元" 2 "人均50-100元" 3 "人均100-200元" 4 "人均200-300元" 5 "人均300元以上" 
label value expense_pc_cat expense_pc_cat

label define tanguan   1 "抖音探官" 0 "非抖音探官" 
label value tanguan tanguan

label define group_purchaseDY   1 "抖音端口内有团购产品" 0 "抖音端口内无团购产品" 
label value group_purchaseDY group_purchaseDY

label define chain_rest   1 "连锁店" 0 "非连锁店" 
label value chain_rest chain_rest

* Add Variable Labels
label var loglike "点赞数(log)"
label var logcomment "评论数(log)"
label var logforward "转发数(log)"
label var logcollection "抖音店铺收藏量"
label var rate_collectionDY "抖音上店铺种草率"
label var group_purchaseDY "抖音端口内有团购产品"
label var stdscore_total "大众点评上门店综合评分"
label var stdscore_taste "大众点评上门店口味评分"
label var stdscore_envir "大众点评上门店环境评分"
label var stdscore_serv  "大众点评上门店服务评分"
label var lognpoi_around "门店附近商家数(log)"
label var logexpense_pc  "人均消费水平(log)"
label var style "门店菜系"
label var vdur "距离视频发布天数"
label var vlength "视频时长"
label var expense_pc "人均消费水平"


*---------------------------------- 影响视频赞评转的因素 ----------------------------*
cap program drop descriptive_summary
program descriptive_summary
	
	destring 视频ID, generate(video_id)
	destring 店铺ID, generate(rest_id)  
	
	*---------------------------------- 关于视频特征的描述性统计 ----------------------------*
	* 视频发布时间
	histogram ymd if ymd >= 22097, width(14) freq fcolor("181 53 19") lcolor(white) lwidth(thin) lpattern(opacity) fcolor("181 53 19") lcolor(white) lwidth(thin) lpattern(opacity) ///
		title("样本探店视频的发布时间分布") ytitle("视频个数") xtitle("日期")
	graph export "plots/video_time_dist.png", replace

	* 视频发布时长+点赞数分布
	graph bar (count) video_id if ymd >= 22097, over(vlength_cat) ///
			title("样本探店视频的视频时长分布") ytitle("视频个数") bar(1, color("181 53 19")) 
		graph export "plots/video_length_dist.png", replace

	preserve 
		keep like_cat vlength_cat
		bys  like_cat vlength_cat: egen N = count(1)
		duplicates drop
		reshape wide N ,i(vlength_cat) j(like_cat)

		graph bar N1 N2 N3 N4 N5, over(vlength_cat) stack percentages ///
			title("不同时长探店视频的点赞数分布") ///
			bar(1, color("255 151 122")) ///
			bar(2,color("255 98 56")) ///
			bar(3,color("221 95 0")) ///
			bar(4, color("181 53 19")) ///
			bar(5, color("139 0 18")) graphregion(color(white)) ///
			legend(order(1 "1K-3K赞" 2 "3K-5K赞" 3 "5K-1W赞" 4 "1W-2W赞" 5 ">2W赞" )) 
		graph export "plots/video_length_dist_pct.png", replace
	restore

	* 视频发布作者及点赞数分布
	graph hbar (count) video_id if ymd >= 22097, over(tanguan) ///
		title("样本探店视频的发布者分布") ytitle("视频个数") bar(1, color("181 53 19")) 
	graph export "plots/video_tanguan_dist.png", replace


	preserve 
		keep like_cat tanguan
		bys  like_cat tanguan: egen N = count(1)
		duplicates drop
		reshape wide N ,i(tanguan) j(like_cat)

		graph hbar N1 N2 N3 N4 N5, over(tanguan) stack percentages ///
			title("视频发布者为探官/非探官的点赞数对比") ///
			legend(order(1 "1K-3K赞" 2 "3K-5K赞" 3 "5K-1W赞" 4 "1W-2W赞" 5 ">2W赞" )) ///
			bar(1, color("255 151 122")) ///
			bar(2,color("255 98 56")) ///
			bar(3,color("221 95 0")) ///
			bar(4, color("181 53 19")) ///
			bar(5, color("139 0 18")) graphregion(color(white))
		graph export "plots/video_tanguan_dist_pct.png", replace
	restore

	*---------------------------------- 关于门店特征的描述性统计 ----------------------------*
	* 门店特征：菜系、人均消费水平、商圈流量、是否有抖音团购、点评上评分
	
	** 点评评分分布
	histogram score_total if ymd >= 22097, width(0.05) freq fcolor("181 53 19") lcolor(white) lwidth(thin) lpattern(opacity) ///
			title("样本探店视频的点评综合评分分布") ytitle("视频个数") xtitle("大众点评上的门店综合评分")
		graph export "plots/video_score_total_dist.png", replace

	** 附近商家数分布
	histogram npoi_around if ymd >= 22097, width(100) freq fcolor("181 53 19") lcolor(white) lwidth(thin) lpattern(opacity) ///
			title("样本探店视频的门店附近商家数分布") ytitle("视频个数") xtitle("门店附近商家数")
		graph export "plots/video_npoi_around_dist.png", replace

	** 菜系分布及点赞数分布
	graph bar (count) video_id if ymd >= 22097, over(style, label(labsize(*0.8)))  ///
		title("样本探店视频的门店菜系分布") ytitle("视频个数") bar(1, color("181 53 19")) 
	graph export "plots/rest_style_dist.png", replace
	
	preserve 
		keep like_cat style
		bys  like_cat style: egen N = count(1)
		duplicates drop
		reshape wide N ,i(style) j(like_cat)

		egen N = rowtotal(N1 N2 N3 N4 N5)
		gen share_N5 = N5/N
		gen share_N45 = (N4+N5)/N

		graph bar N1 N2 N3 N4 N5, over(style, label(labsize(*0.7)) sort(share_N45) descending) percentages stack ///
			title("不同类型门店探店视频的点赞数分布") ///
			bar(1, color("255 151 122")) ///
			bar(2, color("255 98 56")) ///
			bar(3, color("221 95 0")) ///
			bar(4, color("181 53 19")) ///
			bar(5, color("139 0 18")) graphregion(color(white)) ///
			legend(order(1 "1K-3K赞" 2 "3K-5K赞" 3 "5K-1W赞" 4 "1W-2W赞" 5 ">2W赞" )) 
		graph export "plots/rest_style_dist_pct.png", replace
	restore

	** 人均消费水平及点赞数分布
	graph bar (count) video_id if ymd >= 22097, over(expense_pc_cat)  ///
		title("样本探店视频的门店人均消费水平分布") ytitle("视频个数") bar(1, color("181 53 19")) 
	graph export "plots/rest_expense_pc_dist.png", replace
	
	preserve 
		keep like_cat expense_pc_cat
		bys  like_cat expense_pc_cat: egen N = count(1)
		duplicates drop
		reshape wide N ,i(expense_pc_cat) j(like_cat)

		graph bar N1 N2 N3 N4 N5, over(expense_pc_cat) percentages stack ///
			title("不同人均消费水平门店探店视频的点赞数分布") ///
			bar(1, color("255 151 122")) ///
			bar(2, color("255 98 56")) ///
			bar(3, color("221 95 0")) ///
			bar(4, color("181 53 19")) ///
			bar(5, color("139 0 18")) graphregion(color(white)) ///
			legend(order(1 "1K-3K赞" 2 "3K-5K赞" 3 "5K-1W赞" 4 "1W-2W赞" 5 ">2W赞" )) 
		graph export "plots/rest_expense_pc_dist_pct.png", replace
	restore

	**  抖音有无团购点赞数分布
	preserve 
		keep like_cat group_purchaseDY
		bys  like_cat group_purchaseDY: egen N = count(1)
		duplicates drop
		reshape wide N ,i(group_purchaseDY) j(like_cat)

		graph bar N1 N2 N3 N4 N5, over(group_purchaseDY) stack percentages ///
			title("抖音端内有/无团购产品门店的点赞数对比") ///
			legend(order(1 "1K-3K赞" 2 "3K-5K赞" 3 "5K-1W赞" 4 "1W-2W赞" 5 ">2W赞" )) ///
			bar(1, color("255 151 122")) ///
			bar(2,color("255 98 56")) ///
			bar(3,color("221 95 0")) ///
			bar(4, color("181 53 19")) ///
			bar(5, color("139 0 18")) graphregion(color(white))
		graph export "plots/video_group_purchaseDY_dist_pct.png", replace
	restore

	* 是否为连锁店
	preserve 
		keep like_cat chain_rest
		bys  like_cat chain_rest: egen N = count(1)
		duplicates drop
		reshape wide N ,i(chain_rest) j(like_cat)

		graph hbar N1 N2 N3 N4 N5, over(chain_rest) stack percentages ///
			title("门店是否为连锁店的点赞数对比") ///
			legend(order(1 "1K-3K赞" 2 "3K-5K赞" 3 "5K-1W赞" 4 "1W-2W赞" 5 ">2W赞" )) ///
			bar(1, color("255 151 122")) ///
			bar(2,color("255 98 56")) ///
			bar(3,color("221 95 0")) ///
			bar(4, color("181 53 19")) ///
			bar(5, color("139 0 18")) graphregion(color(white))
		graph export "plots/video_chain_rest_dist_pct.png", replace
	restore

end

** OLS分析：探店视频的转评赞量如何受门店特征、视频特征的影响
cap program drop ols_video_factor
program ols_video_factor

	* 为了解释方便进行标准化
	replace vdur = vdur/10
	gen vdur_sq = vdur*vdur
	label var vdur "距离视频发布天数(10天)"
	label var vdur_sq "距离视频发布天数的平方"

	replace vlength = vlength/60
	gen vlength_sq = vlength * vlength
	label var vlength "视频时长(分钟)"
	label var vlength_sq "视频时长的平方"

	replace expense_pc = expense_pc/100
	gen expense_pc_sq = expense_pc * expense_pc
	label var expense_pc "人均消费水平(百元)"
	label var expense_pc_sq "人均消费水平的平方"

	est clear
	local rest_chars ib8.style stdscore_total expense_pc expense_pc_sq group_purchaseDY lognpoi_around 
	local video_chars vdur vlength vlength_sq tanguan arthor_gender

	reg loglike `rest_chars' `video_chars'
	est sto ols_lglike

	reg logcomment `rest_chars' `video_chars'
	est sto ols_lgcomment

	reg logforward `rest_chars' `video_chars'
	est sto ols_lgforward

	* 提取店铺数量
	gen temp1 = 1
	qui unique 店铺ID, by(temp1) generate(temp2)
	sum temp2
	local n_store = r(max)
	drop temp*

	outreg2 [ols_lglike ols_lgcomment ols_lgforward] using "ols_video_popularity_factors.xls", excel replace nocon dec(3)  ///
				addtext("Number of Restaurants",`n_store')
end


* descriptive_summary
* ols_video_factor



*--------------------------------------------Main  Analysis------------------------------------------*
* 每天保留点赞数最多的视频，然后看视频分布
bys 店铺ID ymd: egen like = max(点赞量)
preserve
	keep 店铺ID like 点赞量 date ymd 
	keep if like == 点赞量
	isid 店铺ID ymd
	tempfile video_info
	save "`video_info'"
restore

* 标记视频最早发布时间
foreach n of numlist 1000 3000 5000 10000{
	gen v`n' = 0
	replace v`n' = 1 if like >= `n' 
	gen temp_`n' =  v`n'*ymd
	bys 店铺ID: egen fst`n'_video_ymd = min(temp_`n')
	replace fst`n'_video_ymd = . if fst`n'_video_ymd == 0
	label var fst`n'_video_ymd "第一个`n'赞以上视频发布时间"

	gen temp2 = like/1000 if ymd == fst`n'_video_ymd
	gen temp3 = like/1000 if inrange(ymd, fst`n'_video_ymd, fst`n'_video_ymd+${per_nweek}*7)

	bys 店铺ID: egen like_fst`n'_video = max(temp2)
	bys 店铺ID: egen like_fst`n'_video_per = total(temp3)
	label var like_fst`n'_video "第一个`n'赞以上视频的点赞数(K)"
	label var like_fst`n'_video_per "第一个`n'赞以上及其他考察期内视频的总点赞数(K)"

	drop v`n' temp*
}

sort 店铺ID date
keep 店铺ID fst*_video_ymd like_fst* chain_rest ///
	style stdscore* logexpense_pc lognpoi_around logcollection rate_collectionDY group_purchaseDY group_purchaseMT  
duplicates drop

isid 店铺ID
tempfile early_video_info
save "`early_video_info'"


* 3. 合并入点评评论信息
import delimited "comments.csv", stringcols(7) clear
ren v7 店铺ID
ren v2 ncomment
gen ymd = date(v1, "YMD")
* 去除 2020.7.1 之前的点评
keep if ymd >= 22097 
format ymd %tdCCYY-NN-DD
ren v1 date
keep date 店铺ID ncomment ymd

* 补全每天的数据
destring 店铺ID, generate(rest_id)
mdesc 店铺ID
xtset rest_id ymd
tsfill, full
replace ncomment = 0 if mi(ncomment)
gen logncomment = log(ncomment+1)
bys rest_id (店铺ID) : gen temp = 店铺ID[_N]
replace 店铺ID = temp
drop temp date
merge m:1 店铺ID using "`shops_info'", keep(1 3) keepus(店铺名称) nogen
merge m:1 店铺ID using "`early_video_info'", keep(3) keepus(*) nogen

* Generate relative period
foreach n of numlist 1000 3000 5000 10000{
	gen rel_date_`n' = ymd - fst`n'_video_ymd
	gen rel_week_`n' = floor(rel_date_`n'/7)
}

gen multivideos = 0
replace multivideos = 1 if like_fst1000_video != like_fst1000_video_per
label var multivideos "首个千赞以上探店视频的考察期内发布了新视频"

cap drop like_fst_video
gen like_fst_video = .

* 视频发布时间是否在抖音上线本地生活(3.5内测)前 
gen after_DY = 0
replace after_DY = 1 if fst1000_video_ymd >= 22344
unique 店铺ID if after_DY == 1 // 58
label var after_DY "视频是否为抖音上线本地生活板块后发布"


*------------------------- A. 研究最早发布的探店视频是否存在处理效应-------------------------*
cap program drop baseline_results
program baseline_results

	loc n = 1000

	cap drop rel_week1
	gen rel_week1 = rel_week_`n' + ${per_nweek} +1 if inrange(rel_week_`n', -${per_nweek}, ${per_nweek}) 
	* T=-1 (+ ${per_nweek} +1) = ${per_nweek}
	loc base_week = ${per_nweek} 
	loc nperiod = 2*${per_nweek} + 1
	matrix coefmat = J(`nperiod',4,.)

	* 提取店铺数量
	gen temp1 = 1
	qui unique 店铺ID if !mi(rel_week1) & !mi(fst`n'_video_ymd), by(temp1) generate(temp2)
	sum temp2
	local n_store = r(max)
	drop temp*

	* Event Study (Base Y)
	reghdfe ncomment ib`base_week'.rel_week1 if !mi(rel_week1) & !mi(fst`n'_video_ymd), /// 
		absorb(店铺ID ymd)
	est sto base_c`n'

	* Plot treatment effects
	foreach i of numlist 1/`nperiod'{
		cap matrix coefmat[`i', 1] = _b[`i'.rel_week1]
		* 95% CI
		cap matrix coefmat[`i', 2] = _b[`i'.rel_week1] - invttail(e(df_r),0.025) * _se[`i'.rel_week1]
		cap matrix coefmat[`i', 3] = _b[`i'.rel_week1] + invttail(e(df_r),0.025) * _se[`i'.rel_week1]
		* Event time
		cap matrix coefmat[`i', 4] = `i' - (${per_nweek} +1)
	}
	matrix colnames coefmat = b lb ub yr
	mat list coefmat

	preserve
		clear
		svmat coefmat, names(col) // Create variables from matrix,  names(col) uses the column names of the matrix to name the variables.

		scatter b yr, msymbol(O) mcolor(gs8) || ///
		rcap lb ub yr, lcolor(gs8) ///
		title("探店视频处理效应随时间变化趋势") ///
		xlabel(-${per_nweek}(1)${per_nweek}) yline(0, lcolor(black) lpattern(dash)) ///
		ytitle("探店视频处理效应", size(medsmall)) xtitle("相对探店视频发布的周数") ///
		legend(off)
		graph export "plots/base_c`n'_${per_nweek}w.png", replace
	restore


	* Event Study (Y in log)
	reghdfe logncomment ib`base_week'.rel_week1 if !mi(rel_week1) & !mi(fst`n'_video_ymd), /// 
		absorb(店铺ID ymd)
	est sto logY_c`n'

	* Plot treatment effects
	foreach i of numlist 1/`nperiod'{
		cap matrix coefmat[`i', 1] = _b[`i'.rel_week1]
		* 95% CI
		cap matrix coefmat[`i', 2] = _b[`i'.rel_week1] - invttail(e(df_r),0.025) * _se[`i'.rel_week1]
		cap matrix coefmat[`i', 3] = _b[`i'.rel_week1] + invttail(e(df_r),0.025) * _se[`i'.rel_week1]
		* Event time
		cap matrix coefmat[`i', 4] = `i' - (${per_nweek} +1)
	}
	matrix colnames coefmat = b lb ub yr
	mat list coefmat

	preserve
		clear
		svmat coefmat, names(col) // Create variables from matrix,  names(col) uses the column names of the matrix to name the variables.

		scatter b yr, msymbol(O) mcolor(gs8) || ///
		rcap lb ub yr, lcolor(gs8) ///
		title("探店视频处理效应随时间变化趋势") ///
		xlabel(-${per_nweek}(1)${per_nweek}) yline(0, lcolor(black) lpattern(dash)) ///
		ytitle("探店视频处理效应", size(medsmall)) xtitle("相对探店视频发布的周数") ///
		legend(off)
		graph export "plots/base_logY_c`n'_${per_nweek}w.png", replace
	restore

	outreg2 [base_c`n' logY_c`n'] using "baseline_results_${per_nweek}w.xls", excel replace nocon dec(3)  ///
				addtext("Number of Restaurants",`n_store', ///
						"Date Fixed Effect","Yes", ///
						"Restaurant Fixed Effect", "Yes", ///
						"Period","T-${per_nweek} to T+${per_nweek}")
end

*baseline_results


*------------------------- B. 异质性分析: 考察不同门店/视频特征对于探店视频投放效果的影响------------------*
local n = 1000 
cap drop rel_week1
gen rel_week1 = rel_week_`n' + ${per_nweek} +1 if inrange(rel_week_`n', -${per_nweek}, ${per_nweek}) 
* T=-1 (+ ${per_nweek} +1) = ${per_nweek}
loc base_week = ${per_nweek} 
loc nperiod = 2* ${per_nweek} + 1

* 提取店铺数量
gen temp1 = 1
qui unique 店铺ID if !mi(rel_week1) & !mi(fst`n'_video_ymd), by(temp1) generate(temp2)
sum temp2
local n_store = r(max)
drop temp*
label var like_fst1000_video "探店视频点赞数"
label var like_fst1000_video_per "探店视频点赞数"
ren like_fst1000_video* like_fstv*

cap program drop plot_coef
program plot_coef
	syntax, nperiod(int) c(str) label_char(str) title(str)

	matrix coefmat = J(`nperiod',4,.)
	foreach i of numlist 1/`nperiod'{
		cap matrix coefmat[`i', 1] = _b[`i'.rel_week1#`c']
		* 95% CI
		cap matrix coefmat[`i', 2] = _b[`i'.rel_week1#`c'] - invttail(e(df_r),0.025) * _se[`i'.rel_week1#`c']
		cap matrix coefmat[`i', 3] = _b[`i'.rel_week1#`c'] + invttail(e(df_r),0.025) * _se[`i'.rel_week1#`c']
		* Event time
		cap matrix coefmat[`i', 4] = `i' - (${per_nweek} +1)
	}
	matrix colnames coefmat = b lb ub yr
	mat list coefmat

	preserve
		clear
		svmat coefmat, names(col)

		scatter b yr, msymbol(O) mcolor(gs8) || ///
		rcap lb ub yr, lcolor(gs8) ///
		title("异质性分析-`label_char'") ///
		xlabel(-${per_nweek}(1)${per_nweek}) yline(0, lcolor(black) lpattern(dash)) ///
		ytitle("交叉项系数", size(medsmall)) xtitle("相对探店视频发布的周数") ///
		legend(off)
		graph export "plots/`title'_c1000_`c'_${per_nweek}w.png", replace
	restore
end

cap program drop plot_coef_style
program plot_coef_style
	syntax, nperiod(int) title(str)
	
	matrix coefmat = J(8*`nperiod',5,.)
	foreach n of numlist 1/7{
		foreach i of numlist 1/`nperiod'{
			loc row = `nperiod' * (`n'-1)+`i'
			cap matrix coefmat[`row', 1] = _b[`i'.rel_week1#`n'.style]
			* 95% CI
			cap matrix coefmat[`row', 2] = _b[`i'.rel_week1#`n'.style] - invttail(e(df_r),0.025) * _se[`i'.rel_week1#`n'.style]
			cap matrix coefmat[`row', 3] = _b[`i'.rel_week1#`n'.style] + invttail(e(df_r),0.025) * _se[`i'.rel_week1#`n'.style]
			* Event time
			cap matrix coefmat[`row', 4] = `i' - (${per_nweek} +1)
			* Style
			cap matrix coefmat[`row', 5] = `n'
		}
	}

	
	matrix colnames coefmat = b lb ub yr style
	mat list coefmat

	preserve
		clear
		svmat coefmat, names(col)

		export excel plots/`title'_c1000_style_${per_nweek}w.xlsx, firstrow(variable) replace

		/*
		reshape wide b lb ub, i(yr) j(style)
		scatter b1 b2 b3 b4 b5 b6 b7 yr, connect(l l l l l l l l) ///
		title("异质性分析-门店类型(菜系)") ///
		xlabel(-${per_nweek}(1)${per_nweek}) yline(0, lcolor(black) lpattern(dash)) ///
		ytitle("交叉项系数", size(medsmall)) xtitle("相对探店视频发布的周数") ///
		legend(order(1 "日料" 2 "韩料/东南亚菜" 3 "火锅" 4 "自助餐" 5 "快餐小吃烧烤" 6 "北京菜" 7 "川菜"))
		graph export "plots/`title'_c1000_style_${per_nweek}w.png", replace
		*/
	restore
end


************************ Regression Analysis ************************
loc status replace
est clear
loc hetero_chars stdscore_total stdscore_taste stdscore_envir stdscore_serv ///
				 logexpense_pc lognpoi_around ///
				 logcollection rate_collectionDY group_purchaseDY
loc hetero_chars stdscore_taste stdscore_envir stdscore_serv

gen like_fstv_per5W = like_fstv_per - 50


/* Plot treatment effects: A. 不控制视频点赞数
loc chars like_fstv like_fstv_per `hetero_chars'
foreach c of local chars{
	local label_char: var label `c'

	reghdfe ncomment ib`base_week'.rel_week1##c.`c' if !mi(rel_week1) & !mi(fst`n'_video_ymd), /// 
		absorb(店铺ID ymd)
	est sto hetero1b_`c'

	plot_coef, nperiod(`nperiod') c(`c') label_char(`label_char') title("hetero1b")

	reghdfe logncomment ib`base_week'.rel_week1##c.`c' if !mi(rel_week1) & !mi(fst`n'_video_ymd),  /// 
		absorb(店铺ID ymd)
	est sto hetero1l_`c'

	plot_coef, nperiod(`nperiod') c(`c') label_char(`label_char') title("hetero1l")

	outreg2 [hetero1b_`c' hetero1l_`c'] using "hetero_results_`c'_${per_nweek}w.xls", excel replace nocon dec(5) 
}

* 菜系
reghdfe ncomment ib`base_week'.rel_week1##ib8.style if !mi(rel_week1) & !mi(fst`n'_video_ymd), /// 
	absorb(店铺ID ymd)
est sto hetero1b_style
plot_coef_style, nperiod(`nperiod') title("hetero1b")

reghdfe logncomment ib`base_week'.rel_week1##ib8.style if !mi(rel_week1) & !mi(fst`n'_video_ymd), /// 
	absorb(店铺ID ymd)
est sto hetero1l_style
plot_coef_style, nperiod(`nperiod') title("hetero1l")


* Plot treatment effects: B. 控制首个视频点赞数
loc chars `hetero_chars'
foreach c of local chars{
	local label_char: var label `c'

	reghdfe ncomment ib`base_week'.rel_week1##c.`c' ib`base_week'.rel_week1##c.like_fstv if !mi(rel_week1) & !mi(fst`n'_video_ymd), /// 
		absorb(店铺ID ymd)
	est sto hetero2b_`c'

	plot_coef, nperiod(`nperiod') c(`c') label_char(`label_char') title("hetero2b")

	reghdfe logncomment ib`base_week'.rel_week1##c.`c' ib`base_week'.rel_week1##c.like_fstv if !mi(rel_week1) & !mi(fst`n'_video_ymd), /// 
		absorb(店铺ID ymd)
	est sto hetero2l_`c'

	plot_coef, nperiod(`nperiod') c(`c') label_char(`label_char') title("hetero2l")
}

* 菜系
reghdfe ncomment ib`base_week'.rel_week1##ib8.style ib`base_week'.rel_week1##c.like_fstv if !mi(rel_week1) & !mi(fst`n'_video_ymd), /// 
	absorb(店铺ID ymd)
est sto hetero2b_style
plot_coef_style, nperiod(`nperiod') title("hetero2b")

reghdfe logncomment ib`base_week'.rel_week1##ib8.style ib`base_week'.rel_week1##c.like_fstv if !mi(rel_week1) & !mi(fst`n'_video_ymd), /// 
	absorb(店铺ID ymd)
est sto hetero2l_style
plot_coef_style, nperiod(`nperiod') title("hetero2l")


* Plot treatment effects: C. 控制样本期内所有视频点赞数之和	

loc chars `hetero_chars'
foreach c of local chars{
	local label_char: var label `c'
	
	reghdfe ncomment ib`base_week'.rel_week1##c.`c' ib`base_week'.rel_week1##c.like_fstv_per5W if !mi(rel_week1) & !mi(fst`n'_video_ymd), /// 
		absorb(店铺ID ymd)
	est sto hetero3b_`c'

	plot_coef, nperiod(`nperiod') c(`c') label_char(`label_char') title("hetero3b")

	reghdfe logncomment ib`base_week'.rel_week1##c.`c' ib`base_week'.rel_week1##c.like_fstv_per5W if !mi(rel_week1) & !mi(fst`n'_video_ymd), /// 
		absorb(店铺ID ymd)
	est sto hetero3l_`c'

	plot_coef, nperiod(`nperiod') c(`c') label_char(`label_char') title("hetero3l")

	outreg2 [hetero3b_`c' hetero3l_`c'] using "hetero_results_`c'_${per_nweek}w.xls", excel replace nocon dec(5) 

}

* 菜系
reghdfe ncomment ib`base_week'.rel_week1##ibn.style ib`base_week'.rel_week1##c.like_fstv_per5W if !mi(rel_week1) & !mi(fst`n'_video_ymd), /// 
	absorb(店铺ID ymd)
est sto hetero3b_style
*plot_coef_style, nperiod(`nperiod') title("hetero3b")


reghdfe logncomment ib`base_week'.rel_week1##ib8.style ib`base_week'.rel_week1##c.like_fstv_per5W if !mi(rel_week1) & !mi(fst`n'_video_ymd), /// 
	absorb(店铺ID ymd)
est sto hetero3l_style
plot_coef_style, nperiod(`nperiod') title("hetero3l")

outreg2 [hetero3l_style] using "hetero_results_style_${per_nweek}w.xls", excel replace nocon dec(5) 


*/

*---------------------------------------------------------------------------------------------*














/********************** Pattern Exploratory Analysis ************************ 
* 分门店 点评上评论数量和视频发布时间关系
preserve
	* merge video info
	merge 1:1 店铺ID ymd using "`video_info'", keep(1 3) keepus(like) nogen

	levelsof 店铺ID, local(restlist)
	foreach r of local restlist{

		levelsof 店铺名称 if 店铺ID == "`r'", local(store_name)
		levelsof ymd if !mi(like) & inrange(like,10000,.) & 店铺ID == "`r'", local(v10000)
		levelsof ymd if !mi(like) & inrange(like,1000,10000) & 店铺ID == "`r'", local(v1000)

		cap line ncomment ymd if 店铺ID == "`r'", ///
			lcolor(gs7) title(`store_name') xtitle("日期") ytitle("点评评论数") ///
			xline(`v1000',lcolor(red))
		cap graph export "分门店趋势/`r'.png", replace

		cap line ncomment ymd if 店铺ID == "`r'", ///
			lcolor(gs7) title(`store_name') xtitle("日期") ytitle("点评评论数") ///
			xline(`v1000',lcolor(red)) xline(`v10000',lcolor(blue)) 
		cap graph export "分门店趋势/`r'.png", replace
	}
restore
*/

*duplicates drop rest_id, force
tab group_purchaseDY group_purchaseMT


