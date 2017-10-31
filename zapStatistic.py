#!/usr/bin/python
# coding: utf-8

import logging
import re, sys, argparse
from datetime import datetime
import csv


loglevel="debug"
#logging.basicConfig(filename='example.log',level=logging.DEBUG)
numeric_level = getattr(logging, loglevel.upper(), None)
print "numeric_level = " + str(numeric_level)
logging.basicConfig(level=numeric_level)

REG1 = "onGlobalKeyEvent.*CHANNEL_(UP|DOWN)" 
REG2 = "eXSERV_NOTIFICATION_EVENT_FIRST_FRAME"
resultTab = []

def parseArgs():
	logging.info('parse Args')
	parser = argparse.ArgumentParser(description='zap statsic')
	parser.add_argument('-f' , '--files', default=""    , help='file log to parse')
	parser.add_argument('-c', '--csvOutput'     , default="OFF"      , help='export result to csv file')

	## On parse et on update les variables globals du script
	args = parser.parse_args()
	globals().update(vars(args)) 
	return 0 

def getRegularDate(dateToCheck):
	ismatched = re.match("^([0-9]{4})([0-9]{2})([0-9]{2})T([0-9]{2})([0-9]{2})([0-9]{2})",dateToCheck)
	if  (ismatched):
		return [1, ismatched.group(1)+"/" + ismatched.group(2) +"/" + ismatched.group(3) + " " + ismatched.group(4) + ":" +ismatched.group(5) +":" + ismatched.group(6)]
        else:
    		return [0,"ERROR"];
    


def getZapDuration(start, end):
	date_format = "%H:%M:%S.%f"
	s = datetime.strptime(start, date_format)
	e = datetime.strptime(end, date_format)
	delta = e - s
	return delta.total_seconds() 

def parseLogFile():
	logging.info('parse log file')
	print "files are = "+ files+" and csv is = "+csvOutput 
        zapLineLog = ""
        parsingFileBreaked = 0
	newZapCount = 0	

	for fileName in files.split("#"):
		file = open(fileName, "r") 
		print fileName + " : is currently parsing"; 	
		parsingFileBreaked = 0;
		currentStatisticResult = {}
		newZapCount = 0

		for line in file: 
			if re.findall(REG1, line):
				zapLineLog =  line
			
			if(len(zapLineLog) and re.findall(REG2, line)):
			      liveDisplayLine = line.split(" ");
      			      startZapLine = zapLineLog.split(" ");
                             
		              isRegularStartZapTime = (getRegularDate(startZapLine[0]))[0]
              		      isRegularLiveDispaly = (getRegularDate(liveDisplayLine[0]))[0]

		              # break file parsing if it's wrongly timestamped  
              		      if ((isRegularStartZapTime+isRegularLiveDispaly) != 2) :
		                   parsingFileBreaked = 1;
                		   print "ERROR : File is wrongly timestamped\n" 
		                   break
			      tmpDic = {}
			      tmpDic['startZapDate'] = (getRegularDate(startZapLine[0]))[1]   
			      tmpDic['zappingDuration'] = getZapDuration(startZapLine[2] , liveDisplayLine[2]);
		              currentStatisticResult[newZapCount] = tmpDic
			      # increment the counter
		              newZapCount += 1
      
		              # reset the zapLineLog
		      	      zapLineLog = ""

              
		file.close()
		if parsingFileBreaked == 0:
         		 currentStatisticResult['totalZap'] = newZapCount ; 
		         # save the current statistic array 
		         resultTab.append(currentStatisticResult);



def displayZapStatistic():
	logging.info('display Result')
	size = len(resultTab) 
	filesName = files.split("#")
	cpt = 0	
	
	while cpt < size :
		if(csvOutput == "ON"):
      		 	tmpName = (filesName[cpt])+".csv"
			f = open(tmpName, "wb")
			try:
				c = csv.writer(f)
				c.writerow( ('Date', 'Duration') )
			finally:
				logging.info('can open the csv file')	


		hashSize = (resultTab[cpt])['totalZap']
		jj = 0
		while jj < hashSize:
        		if(csvOutput == "OFF"):
              			print  str(jj)+"   "+(resultTab[cpt])[jj]['startZapDate']+"   "+str((resultTab[cpt])[jj]['zappingDuration'])+ " sec";
	           	else:     
 				c.writerow( ((resultTab[cpt])[jj]['startZapDate'] , str((resultTab[cpt])[jj]['zappingDuration']) ) ) 
			jj += 1
		
		if csvOutput == "ON" :
			f.close()
		cpt +=1          
       


def main(argv):
	parseArgs()
	parseLogFile()
	displayZapStatistic()


main(sys.argv[1:])

