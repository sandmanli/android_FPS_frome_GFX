var color='#FFF';

var chart_GFX=null;
function GFX(a) {
	if(chart_GFX != null){chart_GFX.destroy()}
	var data=getGFX(a);
	chart_GFX=new Highcharts.Chart({
		chart: {
			renderTo: 'GFX',
			type: 'line'
		},
		title: {
			text: 'FPS走势图'
		},
		credits: {
			enabled: false
		},
		xAxis: {
			title: {text: 'uptime(s)'},
			floor: min,
			max: max
		},
		yAxis: [
			{labels: {format: '{value}帧/秒'},title: {text:'FPS'},min: 0},
			{labels: {format: '{value}%'},title: {text:'百分比(%)'},min: 0,opposite: true}
		],
		legend: {
			layout: 'vertical',
			align: 'right',
			verticalAlign: 'top',
			x: 0,
			y: 40
		},
		plotOptions: {
			line:{turboThreshold:0}
		},
		tooltip: {
			shared: true,
			crosshairs: true,
			useHTML: true,
			formatter: function () {
				var s='<small>' + this.x + 's</small><table>';
				$.each(this.points, function () {
					s += '<tr><td style="word-break:keep-all; color: ' + this.series.color + '"><span>' + this.series.name + ':</span></td><td style="text-align: right; color: '+ color + '"><b>' + this.y + '</b></td></tr>';
				});
				var p=isHasElement(start_time,this.x);
				if(p==-1)p=isHasElement(end_time,this.x);
				if(p>-1){
					s += '<tr><td style="word-break:keep-all; color: ' + color + '">最大卡顿:</td><td style="text-align: right; color: '+ color + '"><b>' + max_time[p] + 'ms</b></td></tr>' +
						 '<tr><td style="word-break:keep-all; color: ' + color + '">A：[100,500):</td><td style="text-align: right; color: '+ color + '"><b>' + A[p] + '</b></td></tr>' +
						 '<tr><td style="word-break:keep-all; color: ' + color + '">B：[50,100):</td><td style="text-align: right; color: '+ color + '"><b>' + B[p] + '</b></td></tr>' +
						 '<tr><td style="word-break:keep-all; color: ' + color + '">C：[42,50):</td><td style="text-align: right; color: '+ color + '"><b>' + C[p] + '</b></td></tr>' +
						 '<tr><td style="word-break:keep-all; color: ' + color + '">总帧数:</td><td style="text-align: right; color: '+ color + '"><b>' + frames[p] + '</b></td></tr>' +
						 '<tr><td style="word-break:keep-all; color: ' + color + '">等待次数(≥500ms):</td><td style="text-align: right; color: '+ color + '"><b>' + wait_times[p] + '</b></td></tr>' +
						 '<tr><td style="word-break:keep-all; color: ' + color + '">等待时长:</td><td style="text-align: right; color: '+ color + 's"><b>' + waiting_time[p] + '</b></td></tr></table>';
				}else{
					s += '</table>';
				}
				return s;
			}
		},
		series: data,
		exporting: {enabled: false}
	});
}

function ResetOptions(){
	var defaultOptions = Highcharts.getOptions()
	for (var prop in defaultOptions){
		if (typeof defaultOptions[prop] !== 'function') delete defaultOptions[prop]
	}
}

function ChangeThemes(option){
	var background_img;
	ResetOptions();
	Highcharts.setOptions(themeArr[0]);
	if (option.value == "6"||option.value == "8" ){document.bgColor = '#FFFFFF'}else{document.bgColor = '#DCDCDC'}
	if (option.value == "1"||option.value == "2"||option.value == "3"||option.value == "4"){color='#FFF'}else{color='#333333'}
	if (option.value == "7" ){
		background_img='url(head/sand.png)'
	}else{
		background_img=null
	}
	Highcharts.wrap(Highcharts.Chart.prototype, 'getContainer', function (proceed){
		proceed.call(this);
		this.container.style.background=background_img
	});
	Highcharts.setOptions(themeArr[option.value]);
}