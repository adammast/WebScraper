# WebScraper
A web scraper for tracker.network to get rocket league MMR info

Written By: Adammast


This web scraper is a script that runs through PowerShell and scrapes https://rocketleague.tracker.network/ for Rocket League MMR info for each player listed in a csv file.


SET-UP:
To set it up you just need to place the script in a folder with a csv file containing player names and tracker links. You can edit what the name of the file is in code but by default the csv file should be named "Tracker Links - RLTN Links.csv". Alongside that file should be a folder named "Scrapes". This is where the new csv files will be exported to after the script gets 
through the list of players. The files by default will be named according to the date and time when they were completed. 


RUNNING:
An easy way to run the script is to right click the file and select "Run with PowerShell". 
I'd also recommend setting up a Windows Task Scheduler schedule for it to automatically run each day. Currently each scrape of the website will have a random 10-30 second delay before the next scrape begins. This is to help conceal the fact that it's a scraper and not a human hitting their website.


Players whose names need fixed after running:

Classé
Baba—Yetu#1987
๑w๑#1038
Érid#0001
Kiimmmiiii☆#1423
🛦 Jet 🛦#8754
