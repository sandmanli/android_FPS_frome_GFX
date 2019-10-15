基于systrace GFX统计每帧绘制的帧率和掉帧统计
------
目标需求：实时统计android帧率，无论正在操作任何app  
  
设计原理：
------
*数据来源systrace GFX 的信息  
1、获取方式:  
`adb shell cat /sys/kernel/debug/tracing/trace_pipe`  
2、开始抓取：  
`atrace gfx -b 1024 -c --async_start`  
3、停止获取：  
`atrace gfx --async_stop 1>/dev/null`  
4、解析规则：  
（1）只处理类别为C和postComposition的信息（postComposition：合成后处理,将图像传递到物理屏幕。）  
（2）postComposition前完成的surface信息作为窗口名  
（3）`TX - *`格式的信息为app启动、退出。部分Surface更新，按是否存在记录0/1  
（4）postComposition之后最近一个Vsync记录绘制时间  
（5）帧率统计中，大于500ms的帧间隔不参与，记为静置等待，存储等待总时长和次数  
（6）用户体验掉帧区间评估：  
	A：\[100ms,500ms)，人眼判断卡顿的认知是：人眼有100ms的缓存，大于100ms才感知为卡顿，  
	B：\[50ms,100ms)，20帧是游戏最低可玩的底线，再低就完全无法忍了；常见UI的gif动画也是20帧刷新。  
	C：\[42ms,50ms)，视频体验是24帧录制播放  
（7）vsync间隔超过系统的间隔值记录 D  
  
  
脚本设计思路：
------
* 设备端离线后台shell脚本监控  
* 用busybox的awk做数据提取存为csv  
* 结果获取到PC端用python脚本生成html报告  
  
依赖文件：  
------
* 设备端需存在/data/local/tmp/busybox `（busybox可到官网对应cpu架构下载）` ，命令：  
`adb push busybox /data/local/tmp`  
`adb shell chmod 755 /data/local/tmp/busybox`  
  
脚本文件：
------
* 监控脚本gfx.sh  
`adb shell`    
`sh /data/local/tmp/gfx.sh`    
GFX()参数说明：  
1、$1 = 目标帧率，默认60  
2、$2 = 评估体验卡顿的把控线，默认100ms  
3、$3 = 输出类型：  
		0) ~ 默认只输出帧率  
		1）~ 增加APP内容两帧间隔 >42ms 的单帧信息  
		2）~ 增加绘制间隔 >vsync间隔的单帧信息  
		3）~ 只输出APP内容两帧间隔 >42ms 的单帧信息  
		4）~ 只输出绘制间隔 >vsync间隔的单帧信息  
4、$4 = 检查输出结果的间隔，默认间隔1秒  
5、$5 = 检查输出时，满足？帧以上输出条件的才输出  
  
预期监控时长结束后，停止监控：  kill cat /sys/kernel/debug/tracing/trace_pipe 的进程  
  
获取结果  
`adb pull /data/local/tmp/fps`  
  
* 监控脚本systrace.py  
生成报告：`(需安装python环境和pandas库)`  
`python systrace.py fps.csv`  
  
说明：  
1、GFX_HTML是报告的模板文件，数据采用的是生成js动态加载的形式，脚本会将其复制到传参目录下  
2、处理csv数据存为`data/?.js`(?对应包名的数组index)，list.js为选择框信息的数组  
3、查看报告数据需要浏览器有本地读写权限：  
chrome: `start chrome.exe --allow-file-access-from-files`  
firefox: `about:config 中 privacy.file_unique_origin属性false`  
4、报告数据刷新会在选择后更新  
![](/report_demo/report.png)  
