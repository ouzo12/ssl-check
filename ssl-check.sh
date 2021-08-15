#!/bin/bash
#certificate expires less than 30 days will be tagged with ALERT
alert=30

if [ "$1" = "" ]; then
echo "
<html>
<head>
<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
<body style=\"background-color:bbb;\">
<style>
* {
  box-sizing: border-box;
}

/* Create two equal columns that floats next to each other */
.column {
  float: left;
  width: 20%;
  padding: 1px;
}

/* Clear floats after the columns */
.row:after {
  content: \" \";
  display: table;
  clear: both;
}
</style>
</head>
<body>
" > index.html

echo "<div class=\"row\"> <div class=\"column\" style=\"background-color:#aaa;\"><h2>Site</h2></div> <div class=\"column\" style=\"background-color:#aaa;\"><h2>Issued</h2></div> <div class=\"column\" style=\"background-color:#aaa;\"><h2>Expires</h2></div> <div class=\"column\" style=\"background-color:#aaa;\"><h2>Subject</h2></div> <div class=\"column\" style=\"background-color:#aaa;\"><h2>Issuer</h2></div> </div>" >> index.html

for i in `ls sites`; do
  info=`echo "QUIT" | openssl s_client -servername $i -connect $i:443 2>/dev/null | openssl x509 -noout -dates -subject -issuer`
  issued=`echo $info`
  newissued=`echo ${issued#*notBefore=}`
  myissued=`echo ${newissued%%notAfter=*}`
  newexpire=`echo ${issued#*notAfter=}`
  myexpire=`echo ${newexpire%%subject=*}`
  mydate=`date -d "$myexpire" +"%s"`
  myorgdate=`date +"%s"`
  mydiffdate=`echo $(( (mydate - myorgdate) / 86400 ))`
  if [ "$mydiffdate" -lt "$alert" ]; then
    mydiffdate="$mydiffdate days <font color=\"red\">***ALERT***</font>"
  else
    mydiffdate="$mydiffdate days"
  fi
  mysubject=`echo "QUIT" | openssl s_client -servername $i -connect $i:443 2>/dev/null | openssl x509 -noout -text | grep -A1 "X509v3 Subject Alternative Name:" | grep DNS | sed 's/DNS://g'`
  newissuer=`echo ${issued#*issuer=}`
  newissuer2=`echo ${newissuer#*O =}`
  myissuer=`echo ${newissuer2%%CN =*} | sed 's/,//g' | sed 's/"//g'`
  echo "<div class=\"row\"> <div class=\"column\" style=\"background-color:#bbb;\"><p>$i</p></div> <div class=\"column\" style=\"background-color:#bbb;\"><p>$myissued</p></div> <div class=\"column\" style=\"background-color:#bbb;\"><p>$myexpire - $mydiffdate</p></div> <div class=\"column\" style=\"background-color:#bbb;\"><p>$mysubject</p></div> <div class=\"column\" style=\"background-color:#bbb;\"><p>$myissuer</p></div> </div>" >> index.html
done
echo "</body></html>" >> index.html

elif [ "$1" = "-help" ]; then
 echo "$0 usage"
 echo "$0 <domainname> <port>"
else
 if [ "$2" = "" ]; then
  port=443
 else
  port="$2"
 fi
  info=`echo "QUIT" | openssl s_client -servername $1 -connect $1:$port 2>/dev/null | openssl x509 -noout -dates -subject -issuer`
  issued=`echo $info`
  newissued=`echo ${issued#*notBefore=}`
  myissued=`echo ${newissued%%notAfter=*}`
  newexpire=`echo ${issued#*notAfter=}`
  myexpire=`echo ${newexpire%%subject=*}`
  mydate=`date -d "$myexpire" +"%s"`
  myorgdate=`date +"%s"`
  mydiffdate=`echo $(( (mydate - myorgdate) / 86400 ))`
  mydiffdate="$mydiffdate days"
  mysubject=`echo "QUIT" | openssl s_client -servername $1 -connect $1:$port 2>/dev/null | openssl x509 -noout -text | grep -A1 "X509v3 Subject Alternative Name:" | grep DNS | sed 's/DNS://g' | sed 's/  //g'`
  newissuer=`echo ${issued#*issuer=}`
  newissuer2=`echo ${newissuer#*O =}`
  myissuer=`echo ${newissuer2%%CN =*} | sed 's/,//g' | sed 's/"//g'`
  echo "$1:$port - $mydiffdate Certificate for ($mysubject) Issued by $myissuer at ($myexpire)"
fi
exit
