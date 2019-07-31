import gspread
import requests
import csv
import datetime

from oauth2client.service_account import ServiceAccountCredentials
from bs4 import BeautifulSoup

now = datetime.datetime.now()
readibletime =  now.strftime("%Y-%m-%d_%H-%M-%S")

scope = ['https://spreadsheets.google.com/feeds', 'https://www.googleapis.com/auth/drive']
credentials = ServiceAccountCredentials.from_json_keyfile_name('Trackers-10a10d9d831a.json', scope)
gc = gspread.authorize(credentials)

Outputcsv = "Scrapes/%s.csv" % (readibletime)
LatestSeason = 10
Seasons = [10]
GamesPlayed = True

def readTrackerList():
    wks = gc.open('Tracker Links').sheet1
    names = wks.col_values(1)
    links = wks.col_values(2)
    return names, links

def csvdostuff():
    '''I/O for CSV'''
    header = ["Name","Tracker"]
    for season in Seasons:
        if GamesPlayed == True:
            header.extend(["1s_MMR", "_2s_MMR", "Solo_3s_MMR", "3s_MMR", "1s_GP", "2s_GP", "Solo_3s_GP", "3s_GP"])
        else:
            header.extend(["1s_MMR", "_2s_MMR", "Solo_3s_MMR", "3s_MMR"])
    names, links = readTrackerList()
    with open(Outputcsv, 'w', newline='') as csvwrite:
        w = csv.writer(csvwrite, delimiter=',')
        w.writerow(header)
        i = 0 #count of each row in the Tracker Links
        for i in range(0, len(names)):
            try:
                name,link = names[i], links[i]
                linksplit = link.split('profile/')
                unpack = [ x for x in linksplit[1].split('/') if x]
                if "mmr" in unpack:
                    mmr,platform,gamertag = unpack
                else:
                    platform,gamertag = unpack
                data = rlscrape(gamertag,platform)
                newrow = dicttolist(data)
                newrow.insert(0, name.encode("ascii", "replace"))
                newrow[0] = newrow[0].decode("ascii")
                newrow.insert(1, link)
                w.writerow(newrow)
                i += 1
                print(i,name,gamertag)
            except:
                i += 1
                print("Error on line {0}".format(i))

def rlscrape(gamertag,platform):
	'''Python BeautifulSoup4 Webscraper to https://rocketleague.tracker.network/ and grab Season 9 and 10'''
	#clienterrors = [400,401,402,403,404] #future proof
	#servererrors = [500,501,502,503,504,505,506,507,508,510,511] #future proof
	playerdata = {} #define the playerdata dict
	playerdata[gamertag] = {} #definte the gamertag dict
	playlistdict = {0:'Un-Ranked',10:'Ranked Duel 1v1',11:'Ranked Doubles 2v2',12:'Ranked Solo Standard 3v3',13:'Ranked Standard 3v3'}
	webpath = "https://rocketleague.tracker.network"
	for season in Seasons:
		playerdata[gamertag][season] = {} #define the season dict
		seasonid = "season-%s" % (season)
		if LatestSeason == season:
			tracker = "%s/%s/%s/%s" % (webpath,'profile/mmr',platform,gamertag)
			page = requests.get(tracker)
			if page.status_code == 200:
				content = page.content
				soup = BeautifulSoup(content, features="lxml")
				for numrank,playlist in playlistdict.items():
					try:
						soup.find('a',{"data-id": numrank }).find('span').text
					except:
						playerdata[gamertag][season][playlist] = None
					else:
						playerdata[gamertag][season][playlist] = {} #define the playlist dict
						mmr = soup.find('a',{"data-id": numrank }).find('span').text
						gamesplayed = soup.find('div',{"data-id": numrank }).find('div').find('span').text
						division = soup.find('div',{"data-id": numrank }).select('div > h4')[2].text
						rank = soup.find('div',{"data-id": numrank }).select('div > span')[2].text	
						playerdata[gamertag][season][playlist]['MMR'] = mmr
						playerdata[gamertag][season][playlist]['Games Played'] = gamesplayed
						playerdata[gamertag][season][playlist]['Rank'] = rank #futureproof
						playerdata[gamertag][season][playlist]['Rank Division'] = division #futureproof
		else:
			tracker = "%s/%s/%s/%s" % (webpath,'profile',platform,gamertag)
			page = requests.get(tracker)
			if page.status_code == 200:
				content = page.content
				soup = BeautifulSoup(content, features="lxml")
				#loop through playlistdict to get data then apply that to the soup to sort it
				for numrank,playlist in playlistdict.items():
					try:
						souptable = soup.find(id=seasonid).select('table > tbody')[0].select('tr')[1:]
					except:
						playerdata[gamertag][season][playlist] = None
					else:
						playerdata[gamertag][season][playlist] = {} #define the playlist dict
						souptable = soup.find(id=seasonid).select('table > tbody')[0].select('tr')[1:]
						i = 0 #use a count to sort through the souptable for each playlist's data
						for soupdata in souptable:
							soupplaylist = soup.find(id=seasonid).select('table > tbody')[0].select('tr')[i].select('td')[1].text.split('\n')[1]
							if playlist == soupplaylist: #loop through and match playlist to webscrape
								mmr = soup.find(id=seasonid).select('table > tbody')[0].select('tr')[i].select('td')[2].text
								gamesplayed = soup.find(id=seasonid).select('table > tbody')[0].select('tr')[i].select('td')[3].text
								playerdata[gamertag][season][playlist]['MMR'] = mmr.strip()
								if 'n/a' not in gamesplayed:
									playerdata[gamertag][season][playlist]['Games Played'] = gamesplayed.strip()
								else:
									playerdata[gamertag][season][playlist]['Games Played'] = None
							i += 1	
	return playerdata

def dicttolist(data):
	newdict = {}
	for gamertag,gdata in data.items():
		for season,sdata in gdata.items():
			newdict[season] = {'MMR_1s': None, 'MMR_2s': None, 'MMR_Solo3s': None, 'MMR_3s': None, 'GamesPlayed_1s': None, 'GamesPlayed_2s': None, 'GamesPlayed_Solo3s': None, 'GamesPlayed_3s': None}
			for playlist,pdata in sdata.items():
				if playlist in 'Ranked Duel 1v1' and pdata is not None and pdata.items():
					newdict[season]['MMR_1s'] = pdata['MMR']
					newdict[season]['GamesPlayed_1s'] = pdata['Games Played']
				if playlist in 'Ranked Doubles 2v2' and pdata is not None  and pdata.items():
					newdict[season]['MMR_2s'] = pdata['MMR']
					newdict[season]['GamesPlayed_2s'] = pdata['Games Played']
				if playlist in 'Ranked Solo Standard 3v3' and pdata is not None  and pdata.items():
					newdict[season]['MMR_Solo3s'] = pdata['MMR']
					newdict[season]['GamesPlayed_Solo3s'] = pdata['Games Played']
				if playlist in 'Ranked Standard 3v3' and pdata is not None  and pdata.items():
					newdict[season]['MMR_3s'] = pdata['MMR']
					newdict[season]['GamesPlayed_3s'] = pdata['Games Played']
	newlist = []
	for season,v in newdict.items():
		if GamesPlayed == True:
			newlist.extend([v['MMR_1s'],v['MMR_2s'],v['MMR_Solo3s'],v['MMR_3s'],v['GamesPlayed_1s'],v['GamesPlayed_2s'],v['GamesPlayed_Solo3s'],v['GamesPlayed_3s']])
		else:
			newlist.extend([v['MMR_1s'],v['MMR_2s'],v['MMR_Solo3s'],v['MMR_3s']])
	return newlist

def orderops():
	csvdostuff()
orderops()