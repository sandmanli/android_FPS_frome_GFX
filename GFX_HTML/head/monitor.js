function getGFX(a){
	var fps=[], Score=[], OKTF=[];
	for (var i=0; i < Surface.length; i++){
		if(Surface[i]==a){
			var oktf=decimal((A[i].div(frames[i])).mul(100),2);
			if(TX[i]==TX_N){
				fps.push({x:start_time[i],y:FPS[i]});
				fps.push({x:end_time[i],y:FPS[i]});
				Score.push({x:start_time[i],y:score[i]});
				Score.push({x:end_time[i],y:score[i]});
				OKTF.push({x:start_time[i],y:oktf});
				OKTF.push({x:end_time[i],y:oktf});
			}
		}
	};
	var series=[];
	series.push({name:'FPS',data:fps});
	series.push({name: '得分(%)',data: Score, yAxis: 1});
	series.push({name: '单帧超100ms(%)',data: OKTF, yAxis: 1});
	return series
}