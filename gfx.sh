#!/system/bin/sh
if [ -f /data/local/tmp/busybox ];then
	bb="/data/local/tmp/busybox"
else
	echo "No /data/local/tmp/busybox"
	exit
fi

show_help() {
echo "
Usage: sh gfx.sh [ -t target_FPS ] [ -k KPI ] [ -T output_type ] [ -d delay_time ] [ -f output_frames ] [ -F output_folder ] [ -h ]

POSIX options | GNU long options

	-t   | --target         The target FPS. Default: 60
	-k   | --KPI            The one frame's kpi time for scoring. Default: 100ms
	-T   | --type           The output type [0~4]. Default: 0
	-d   | --delay          The delay time for checking output. Default: 1 (S)
	-f   | --frames         The frames number to output resulr. Default: 20
	-F   | --folder         The folder name for resulr csvs(/data/local/tmp/). Default: fps
	-h   | --help           Display this help and exit
"
}

target=60
KPI=100
type=0
delay=1
frames=20
folder=fps
while :
do
    case $1 in
        -h | --help)
            show_help
            exit 0
            ;;
        -t | --target)
            shift
			target=$1
			shift
            ;;
        -T | --type)
            shift
			type="$1"
			shift
            ;;
        -k | --KPI)
            shift
			KPI=$1
			shift
            ;;
        -d | --delay)
            shift
			delay="$1"
			shift
            ;;
		-f | --frames)
            shift
			frames="$1"
			shift
            ;;
		-F | --folder)
            shift
			folder="$1"
			shift
            ;;
        --) # End of all options
            shift
            break
            ;;
        *)  # no more options. Stop while loop
            break
            ;;	
    esac
done

#参数说明
## $1 = 目标帧率
## $2 = 评估体验卡顿的把控线
## $3 = 输出类型：
##		0) ~ 默认只输出帧率
##		1）~ 增加APP内容两帧间隔 >42ms 的单帧信息
##		2）~ 增加绘制间隔 >vsync间隔的单帧信息
##		3）~ 只输出APP内容两帧间隔 >42ms 的单帧信息
##		4）~ 只输出绘制间隔 >vsync间隔的单帧信息
## $4 = 检查输出结果的间隔
## $5 = 检查输出时，满足？帧以上输出条件的才输出
GFX(){
#如果systrace打开则关闭
if [ `cat /sys/kernel/debug/tracing/tracing_on` -eq 1 ];then
	echo "atrace gfx stop"
	atrace gfx --async_stop 1>/dev/null &
	$bb sleep 3
	kill $!
fi
#vsync 间隔获取
local sync=`dumpsys SurfaceFlinger --latency|$bb awk 'NR==1{r=$1/1000000;if(r<0)r=$1/1000;print r}'`
#当前选中的activity
local hasFocus=`dumpsys input|grep "hasFocus=true"|$bb awk '{print substr($4,1,length($4)-3)}'`
#提取当前显示activity的app
local app=`echo $hasFocus|$bb awk -F "/" '{print $1}'`
#开始输出systrace log: 1M 循环buffer 的gfx信息
echo "atrace gfx -b 1024 -c --async_start"
atrace gfx -b 1024 -c --async_start
#awk解析
$bb awk -F "|" \
-v sync="$sync" \
-v OFS=, \
-v app="$app" \
-v activity="$hasFocus" \
-v target="$1" \
-v kpi="$2" \
-v type="$3" \
-v delay="$4" \
-v fames="$5" \
-v csv=$monitor/fps.csv \
-v csv1=$monitor/dropFrames.csv \
	'BEGIN{ \
		while("cat /sys/kernel/debug/tracing/trace_pipe"|getline){ \
			if(NF==4||$3=="postFramebuffer"){ \
				if($3~/VSYNC-sf|VSYNC-app|VSYNC-sf-app/){ \
					gsub(/.*.) |: tracing_mark_write: C/,"",$1); \
					split($1,T," "); \
					if(f==""){ \
						f=T[3]; \
						logF=1; \
						logD=0; \
						if(type==1){ \
							logD=1 \
						}else{ \
							if(type==2){ \
								logD=2; \
							}else{ \
								if(type==3){ \
									logF=0; \
									logD=1 \
								}else{ \
									if(type==4){ \
										logF=0; \
										logD=2 \
									} \
								} \
							} \
						} \
					}else{ \
						if(post==1){ \
							if(sv!=""){ \
								SV=sv \
							}else{ \
								SV=activity \
							}; \
							p=TX","app",\""SV"\""; \
							t=(T[3]-VSYNC)*1000; \
							if(t>sync){ \
								d=1 \
							}else{ \
								d=0 \
							}; \
							wt=(T[3]-V[p])*1000; \
							if(wt<500){ \
								if(d==1){ \
									if(logD==2){ \
										print VSYNC,T[3],t,$3,p,"\""info"\"">csv1 \
									}else{ \
										if(logD==1){ \
											if(wt>=42)print V[p],T[3],wt,$3,p,"\""info"\"">csv1 \
										} \
									} \
								}; \
								if(logF==1){ \
									N[p]=N[p]+1; \
									Time[p]=Time[p]+wt; \
									if(M[p]==""){ \
										M[p]=wt \
									}else{ \
										if(M[p]<wt)M[p]=wt \
									}; \
									if(wt>=100){ \
										A[p]=A[p]+1 \
									}else{ \
										if(wt>=50){ \
											B[p]=B[p]+1 \
										}else{ \
											if(wt>=42)C[p]=C[p]+1 \
										} \
									} \
								} \
							}else{ \
								if(logF==1&&b[p]!=""){ \
									Stop[p]=Stop[p]+1; \
									StopT[p]=StopT[p]+wt \
								} \
							}; \
							if(logF==1){ \
								if(d==1)D[p]=D[p]+1; \
								if(b[p]=="")b[p]=T[3]; \
								V[p]=T[3]; \
								if(T[3]-f>=delay){ \
									if(length(N)>0){ \
										for(i in N){ \
											if(N[i]>fames){ \
												fps=sprintf("%.1f",N[i]*1000/Time[i]); \
												if(fps>=target){ \
													fps=int(fps); \
													g=1 \
												}else{ \
													g=fps/target \
												}; \
												if(kpi<M[i])h=kpi/M[i];else h=1; \
												ss=sprintf("%.2f",g*60+h*20+(1-A[i]/N[i])*10+(1-B[i]/N[i])*7+(1-C[i]/N[i])*3); \
												print b[i],V[i],fps+0,N[i],sprintf("%.3f",Time[i]/1000)+0,M[i],sprintf("%.3f",StopT[i]/1000)+0,Stop[i]+0,A[i]+0,B[i]+0,C[i]+0,D[i]+0,ss+0,i>>csv; \
												b[i]=V[i]; \
												N[i]=""; \
												Time[i]=""; \
												M[i]=""; \
												StopT[i]=""; \
												Stop[i]=""; \
												A[i]=""; \
												B[i]=""; \
												C[i]=""; \
												D[i]="" \
											} \
										} \
									}; \
									f=T[3]; \
								} \
							} \
						};
					}; \
					VSYNC=T[3];                 
					state=1; \
					TX=0; \
					post=0; \
					sv=""; \
					info="" \
				}else{ \
					if(NF==3){	\
						state=0; \
						post=1 \
					}else{ \
						if(state==1&&$3!~/HW_VSYNC_ON_0|HW_VSYNC_0|hasClientComposition|FrameMissed|FramebufferSurface/){ \
							if(logD>0){ \
								if(info="")info=$3;else info=info"\n"$3 \
							}; \
							if($3~/TX - /){ \
								TX=1 \
							}else{ \
								l=split($3,Check,"."); \
								if(l>2){ \
									l=split($3,tmp,"/"); \
									if(l>1){ \
										sv=$3; \
										l=split($3,Check," "); \
										if(l==1){ \
											app=tmp[1]; \
											activity=$3 \
										} \
									}else{ \
										sv=$3 \
									} \
								}else{ \
									sv=$3 \
								} \
							} \
						} \
					} \
				} \
			} \
		}; \
		if(length(N)>0){ \
			for(i in N){ \
				if(N[i]>0){ \
					fps=sprintf("%.1f",N[i]*1000/Time[i]); \
					if(fps>=target){ \
						fps=int(fps); \
						g=1 \
					}else{ \
						g=fps/target \
					}; \
					if(kpi<M[i])h=kpi/M[i];else h=1; \
					ss=sprintf("%.2f",g*60+h*20+(1-A[i]/N[i])*10+(1-B[i]/N[i])*7+(1-C[i]/N[i])*3); \
					print b[i],V[i],fps+0,N[i],sprintf("%.3f",Time[i]/1000)+0,M[i],sprintf("%.3f",StopT[i]/1000)+0,Stop[i]+0,A[i]+0,B[i]+0,C[i]+0,D[i]+0,ss+0,i>>csv \
				} \
			} \
		} \
	}' &
#获取cat进程pid
local catPid=`$bb ps|$bb awk '$4=="cat"&&$5=="/sys/kernel/debug/tracing/trace_pipe"{print $1}'`
echo "cat Pid="$catPid
#等待 cat /sys/kernel/debug/tracing/trace_pipe进程退出，后子进程退出
wait
#停止systrace
if [ `cat /sys/kernel/debug/tracing/tracing_on` -eq 1 ];then
	echo "finish: atrace gfx stop"
	atrace gfx --async_stop 1>/dev/null &
	$bb sleep 3
	kill $!
fi
}

#main
${testresult="/data/local/tmp/"} 2>/dev/null
monitor="$testresult/$folder"
if [ -d $monitor ];then
    $bb rm -r $monitor
fi
mkdir -p $monitor
if [ $type -lt 3 ];then
	echo "start time,end time,FPS,frames,Time(S),max time(ms),waiting time(S),wait times,A,B,C,D,score,TX,app,Surface" >$monitor/fps.csv
fi
if [ $type -gt 0 ];then
	echo "start VSYNC,end VSYNC,used time(ms),VSYNC type,TX,app,Surface,info" >$monitor/dropFrames.csv
fi

GFX $target $KPI $type $delay $fames
