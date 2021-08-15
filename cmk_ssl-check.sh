#!/bin/bash
#certificate expires less than 30 days will be tagged with ALERT
alert=50
warning=60

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
   status=2
   statustxt="CRITICAL"
elif [ "$mydiffdate" -lt "$warning" ]; then
   status=1
   statustxt="WARNING"
else
   status=0
   statustxt="OK"
fi
mysubject=`echo "QUIT" | openssl s_client -servername $i -connect $i:443 2>/dev/null | openssl x509 -noout -text | grep -A1 "X509v3 Subject Alternative Name:" | grep DNS | sed 's/DNS://g' | sed 's/  //g'`
newissuer=`echo ${issued#*issuer=}`
newissuer2=`echo ${newissuer#*O =}`
myissuer=`echo ${newissuer2%%CN =*} | sed 's/,//g' | sed 's/"//g'`

echo "$status SSL_$i count=$mydiffdate:$alert;$warning;0; $statustxt: $mydiffdate days remains for ($mysubject) Expires at $myexpire"
done
