# -*- coding: utf-8 -*-
import codecs
import datetime as dt
import os
import pandas as pd
import sys
import time


def log(info):
    print('%s %s'%(dt.datetime.now(), info))

def copyFiles(sourceDir, targetDir):
    copyFileCounts = 0
    log(sourceDir)
    log('copy %s the %sth file'%(sourceDir,copyFileCounts))
    for f in os.listdir(sourceDir):
        sourceF = os.path.join(sourceDir, f)
        targetF = os.path.join(targetDir, f)

        if os.path.isfile(sourceF):
            if not os.path.exists(targetDir):
                os.makedirs(targetDir)
            copyFileCounts +=  1
            if not os.path.exists(targetF) or (os.path.exists(targetF) and (os.path.getsize(targetF) !=  os.path.getsize(sourceF))):
                open(targetF, "wb").write(open(sourceF, "rb").read())
                log('%s finish copying'%targetF)
            else:
                log('%s exist'%targetF)

        if os.path.isdir(sourceF):
            copyFiles(sourceF, targetF)

def GFX(csvPath,jsFolder):
    list = []
    log('GFX Start')
    data = pd.read_csv(r'%s'%csvPath, warn_bad_lines=False, error_bad_lines=False, low_memory=False).fillna(value = 'null')
    apps = data['app'].unique().tolist()
    i=0
    for P in apps :
        data_app = data[data['app'] == P]
        start_time = data_app['start time'].astype('Float64').values.tolist()
        end_time = data_app['end time'].astype('Float64').values.tolist()
        FPS = data_app['FPS'].astype('Float64').values.tolist()
        frames = data_app['frames'].astype('int').tolist()
        Time = data_app['Time(S)'].astype('Float64').values.tolist()
        max_time = data_app['max time(ms)'].astype('Float64').values.tolist()
        waiting_time = data_app['waiting time(S)'].values.tolist()
        wait_times = data_app['wait times'].astype('int').values.tolist()
        A = data_app['A'].astype('int').values.tolist()
        B = data_app['B'].astype('int').values.tolist()
        C = data_app['C'].astype('int').values.tolist()
        D = data_app['D'].astype('int').values.tolist()
        score = data_app['score'].values.tolist()
        TX = data_app['TX'].astype('int').values.tolist()
        Surface = data_app['Surface'].values.tolist()
        for l in range(len(start_time)):
            start_time[l] = round(start_time[l], 3)+0
            end_time[l] = round(end_time[l], 3)+0
            FPS[l] = round(FPS[l], 1)+0
            Time[l] = round(Time[l], 3)+0
            max_time[l] = round(max_time[l], 3)+0
            waiting_time[l] = round(waiting_time[l], 3)+0
        list.append([P, data_app['Surface'].unique().tolist()])
        js ="""var min=%s;
var max=%s;
var start_time = %s;
var end_time = %s;
var FPS = %s;
var score = %s;
var frames = %s;
var Time = %s;
var max_time = %s;
var waiting_time = %s;
var wait_times = %s;
var A = %s;
var B = %s;
var C = %s;
var D = %s;
var TX = %s;
var Surface = %s;
"""%(min(start_time),max(end_time),start_time,end_time,FPS,score,frames,Time,max_time,waiting_time,wait_times,A,B,C,D,TX,Surface)
        f = codecs.open(r'%s/%s.js'%(jsFolder,i), "w", "utf-8")
        f.write('%s'%js)
        f.close()
        i+=1
    f = codecs.open(r'%s/list.js'%jsFolder, "w", "utf-8")
    f.write('list = %s'%list)
    f.close()
    log('GFX Finish')
    return list

if __name__ == '__main__':
    DATA_Path = os.path.dirname(sys.argv[1])
    dataPath = os.path.join(DATA_Path,'data')

    import shutil
    if os.path.exists(dataPath) :
        try:
            shutil.rmtree(dataPath)
        except os.error as err:
            time.sleep(0.5)
            try:
                shutil.rmtree(dataPath)
            except os.error as err:
                log("Delete data Error!!!")
    copyFiles(os.path.join(os.path.dirname(os.path.realpath(sys.argv[0])), 'GFX_HTML'), DATA_Path)
    if not os.path.exists(dataPath) :
        os.mkdir(dataPath)
    
    GFX(sys.argv[1], dataPath)
