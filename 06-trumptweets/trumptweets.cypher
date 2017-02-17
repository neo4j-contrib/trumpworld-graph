// trump tweets from buzzfeed article:
// creates a twitter graph with mentions and hashtags
// also marks assumed retweets
// creates a time tree
// reports frequently used hashtags
// and mentions

// tag::tweetgraph[]
create constraint on (u:User) assert u.name is unique;
create constraint on (t:Tag) assert t.name is unique;
create constraint on (t:Tag) assert t.id_str is unique;
create constraint on (l:Link) assert l.url is unique;

load csv with headers from "http://data.buzzfeed.com/projects/2016-11-trump-tweets/tweets_realdonaldtrump.csv" as row 
create (t:Tweet) set t=row;

match (t:Tweet)
WHERE NOT t.created_at contains "GMT"
set t.created = apoc.date.parse(t.created_at,"s","E MMM dd HH:mm:ss Z yyyy");

match (t:Tweet)
WHERE t.created_at contains "GMT"
set t.created = apoc.date.parse(split(t.created_at," (")[0],"s","E MMM dd yyyy HH:mm:ss 'GMT'Z");

match (t:Tweet) 
with t, split(apoc.text.regreplace(t.text,"(([@#]\\w+|https?://[\\w./?#-]+))","§$1§"),"§") as parts
foreach (tagName IN filter(p IN parts WHERE p STARTS WITH "#") |
   MERGE (tag:Tag {name:substring(toLower(tagName),1)})
   MERGE (t)-[:TAGGED]->(tag)
)
foreach (screenName IN filter(p IN parts WHERE p STARTS WITH "@") |
   MERGE (u:User {name:substring(toLower(screenName),1)}) ON CREATE SET u.screenName = substring(screenName,1)
   MERGE (t)-[:MENTIONED]->(u)
)
foreach (url IN filter(p IN parts WHERE p STARTS WITH "http") |
   MERGE (l:Link {url:url})
   MERGE (t)-[:LINKED]->(l)
)

WITH * WHERE "@realDonaldTrump" IN parts  SET t:Retweet;

MATCH (t:Tweet) WHERE t.text starts with '"' SET t:Retweet;
// end::tweetgraph[]


// tag::tweetreport[]
MATCH (t:Tweet) where not t:Retweet return count(*);

MATCH (n:Tag) RETURN n.name, size( (n)--() ) as deg ORDER BY deg desc  LIMIT 25;

MATCH (n:User) RETURN n.name, size( (n)<-[:MENTIONED]-() ) as deg ORDER BY deg desc  LIMIT 25;
// end::tweetreport[]


// tweet at what hour of the day (ET)
// https://dl.dropboxusercontent.com/u/14493611/tweet-time.jpg

// tag::tweethour[]
MATCH (t:Tweet) WHERE NOT t:Retweet
RETURN apoc.date.format(t.created,"s","HH","GMT-5") as hour, count(*) as c
ORDER BY c DESC LIMIT 5;
// end::tweethour[]

// tag::timetree[]
MATCH (t:Tweet)
WITH SPLIT(apoc.date.format(t.created,"s","yyyy-MM-dd"),"-") as parts,t
MERGE (y:Year {year:parts[0]})
MERGE (m:Month {month:parts[1]})-[:IN_YEAR]->(y)
MERGE (d:Day {day:parts[2]})-[:IN_MONTH]->(m)
MERGE (t)-[:CREATED]->(d);
// end::timetree[]

MATCH (y:Year)<--(m:Month)<--(d:Day)<--(t:Tweet) 
RETURN y.year,m.month, count(*)
ORDER BY count(*) DESC LIMIT 10;

// top words

MATCH (t:Tweet) WHERE NOT t:Retweet
UNWIND split(apoc.text.regreplace(toLower(t.text),"\\W+"," ")," ") AS word
WITH word WHERE length(word) > 3 and not word IN ["http","https"]
RETURN word, count(*) as c
ORDER BY c DESC LIMIT 30;

// bigram
MATCH (t:Tweet) WHERE NOT t:Retweet
WITH [word IN split(apoc.text.regreplace(toLower(t.text),"\\W+"," ")," ") 
      WHERE length(word) > 3 and not word IN ["http","https"]] AS words
UNWIND [idx in range(0,length(words)-2) | words[idx..idx+2]] as bigram
RETURN bigram, count(*) as c
ORDER BY c DESC LIMIT 30;

// tag::trigram[]
MATCH (t:Tweet) WHERE NOT t:Retweet
WITH [word IN split(apoc.text.regreplace(toLower(t.text),"\\W+"," ")," ") 
      WHERE length(word) > 3 and not word IN ["http","https"]] AS words
UNWIND [idx in range(0,length(words)-3) | words[idx..idx+3]] as trigram
RETURN trigram, count(*) as c
ORDER BY c DESC LIMIT 30;
// end::trigram[]


