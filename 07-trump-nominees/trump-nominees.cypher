/*
scraped, todo convert into JS node program

https://www.washingtonpost.com/graphics/politics/trump-administration-appointee-tracker/database/
curl -o database.html -L https://www.washingtonpost.com/graphics/politics/trump-administration-appointee-tracker/database/

var $tables = $("table.agencies");
var data = $tables.map(function() { 
   var isText = function() { return this.nodeType == 3; }
   var text = function() { return $(this).text().trim(); }
   var ctext = function() { return $(this).find("*").andSelf().contents().filter(isText).map(text).toArray().join("\t"); }
   var texts = function (x) { return x.map(ctext).toArray() };
   var $table=$(this); 
   return { 
      header: texts($table.find("thead tr th")), 
      data: $table.children("tbody").children("tr[data-has-nominee=true]").map(
         function() { return [[$(this).parent().attr("id")].concat(texts($(this).children("td")))]; }).toArray()
   }
}).get(0);
data.data.map(function(row) { return row.join("\t") }).join("\n");

// $("table.agencies").find("tr[data-has-nominee=true]").map(function() { return $(this).children("td").map(function() { return $(this).children(":first-child, p").text().trim(); }).toArray().join("\t"); }).toArray().join("\n");
*/

LOAD CSV FROM "https://dl.dropboxusercontent.com/u/14493611/trump-nominees-wapost.csv" AS row FIELDTERMINATOR "\t"
RETURN count(*);
// 35

// tag:listpositions[]
LOAD CSV FROM "https://dl.dropboxusercontent.com/u/14493611/trump-nominees-wapost.csv" AS row FIELDTERMINATOR "\t"
RETURN toUpper(row[0]) as agency,toUpper(row[1]) as status,toUpper(row[3]) as name,toUpper(row[4]) as position;
// end:listpositions[]


// tag:importpositions[]
LOAD CSV FROM "https://dl.dropboxusercontent.com/u/14493611/trump-nominees-wapost.csv" AS row FIELDTERMINATOR "\t"
WITH replace(toUpper(row[0]),"-"," ") as agency,toUpper(row[1]) as status,toUpper(row[3]) as name,toUpper(row[4]) as position
WHERE NOT position contains "AMBASSADOR"
MERGE (p:Person {name:name}) SET p.status = status
MERGE (a:Agency {name:agency})
WITH *
CALL apoc.create.relationship(p,position,{status:status},a) YIELD rel
RETURN count(rel);

LOAD CSV FROM "https://dl.dropboxusercontent.com/u/14493611/trump-nominees-wapost.csv" AS row FIELDTERMINATOR "\t"
WITH toUpper(row[0]) as agency,toUpper(row[1]) as status,toUpper(row[3]) as name,toUpper(row[4]) as position
WHERE position contains "AMBASSADOR"
WITH *, split(position,", ")[1] as country
MERGE (p:Person {name:name}) SET p.status = status
MERGE (c:Country {name:country})
MERGE (p)-[r:AMBASSADOR]->(c) SET r.status = status;
// end:importpositions[]


