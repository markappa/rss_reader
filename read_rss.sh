#!/bin/bash
# tested with ANSA news rss
# https://www.ansa.it/sito/ansait_rss.xml
# https://www.ansa.it/lombardia/notizie/lombardia_rss.xml
# https://www.ansa.it/sito/notizie/topnews/topnews_rss.xml
# https://www.ansa.it/sito/notizie/tecnologia/tecnologia_rss.xml

# See here for full list:
# https://www.ansa.it/sito/static/ansa_rss.html


xmlgetnext () {
   local IFS='['
   read -d ']' VAL1 VAL2 VAL3 VAL4
}

readlasttitle () {
   rm -f .templt
   cat .lastTitle | while read U T 
   do
      #echo Read $U"---->"$T >&2
      if [[ $1 == $U ]]
      then
         echo $T
      else
         echo $U $T >> .templt
      fi
   done
   if [[ -f .templt ]] ; then
      mv .templt .lastTitle
   else
      rm -f .lastTitle
      touch .lastTitle
   fi
}

if [[ $1 == "" ]]
then 
   URL=https://www.ansa.it/sito/notizie/topnews/topnews_rss.xml
else
   URL=$1
fi

FIRST=1
LAST=$(readlasttitle $URL)
#echo LAST=$LAST

curl -s $URL | while xmlgetnext ; do
   if [[ $VAL3 != "" ]] ; then
      #echo $VAL3;
      if [ $FIRST -eq 1 ]
      then
         FIRST=0
         echo $URL $VAL3 >> .lastTitle
      fi

      if [[ $LAST == $VAL3 ]]
      then
         #echo No new titles
         exit 0
      fi

      while curl -s -X GET -H "Authorization: Bearer ${SUPERVISOR_TOKEN}"\
         http://supervisor/core/api/states/media_player.mpd | grep -q "playing" ;
      do
         #echo waiting
         sleep 1
      done

      curl -s -X POST -H "Authorization: Bearer ${SUPERVISOR_TOKEN}"\
         -H "Content-Type: application/json"\
         -d "{\"language\":\"it\",\
           \"entity_id\":\"media_player.mpd\",\
           \"message\":\"${VAL3}\"\
         }"\
         http://supervisor/core/api/services/tts/google_translate_say \
         >/dev/null ;

      #echo
      sleep 1

   fi
done

