#!/bin/bash
#
# Ez a script nem hagyja elaludni a gepet, ezert 5 percenkent megmozgatja az egeret.
# Ha a minidlna kiszolgal eppen, akkor szinten ebren tartja a gepet
# Indulaskor kiirja, hogy mennyi ideig fog futni. 
# Ha mar fut, kiirjuk mennyi van meg hatra es valaszthatunk, hogy
# leallitjuk, hozzaadunk 30 percet vagy nem teszunk semmit
# Egy status file-on keresztul tartjuk a kapcsolatot a futo script-tel
# Az ablakok pár másodperc mulva eltunnek maguktol
#
cd ~/.scripts/
# fut mar a script? 
if [ -r mousemove.run ]; then
   # kiirjuk mennyi van meg hatra es valaszthatunk, hogy mit akarunk csinalni
   STOPAFTER=`cat mousemove.status`
   zenity --no-wrap --question --text=$STOPAFTER" perc van még. Mit szeretnél?" --timeout 10 --cancel-label "+30 perc" --ok-label "állj"
   case "$?" in
   # meg plusz 30 percig menjen
   1)
     ((STOPAFTER=STOPAFTER+30))
     echo $STOPAFTER>mousemove.status
     exit
     ;;
   # le akarjuk allitani a script-et
   0)
     echo "0">mousemove.status
     rm mousemove.run
     exit
     ;;
   # nem csinalunk semmit
   *)
     exit
     ;;
   esac
fi
# ha meg nem fut a script, akkor leteszunk egy lock filet
touch mousemove.run
# 30 percig fut majd, ezt letaroljuk egy status file-ba es kiirjuk
STOPAFTER=30
echo $STOPAFTER>mousemove.status
zenity --info --no-wrap --timeout 5 --text $STOPAFTER" percig nem alszik el a PC"
DELAY=60
# ennyit mozog a kurzor es ilyen iranyba kezdi
LENGTH=1
ANGLE=0
# a ciklusvaltozo most true, majd beallitjuk false-ra ha ki kell lepni
CIKLUS=true
while $CIKLUS
do
   # egy pont korul mozog a kurzor
   ((ANGLE=ANGLE+90))
   if [ $ANGLE -gt 270 ] ; then
      ANGLE=0
   fi
   # mozgatjuk a kurzort
   xdotool mousemove_relative --polar $ANGLE $LENGTH
   # megnezzuk a minidlna kiszolgal-e valakit, ha igen, mennie kell a gepnek
   netstat -anp 2>/dev/null |grep ":8200.*ESTABLISHED" >/dev/null
   if [ "$?" == "0" ] || [ -r mousemove.run ]; then
      CIKLUS=true
   else
      CIKLUS=false
   fi
   # hany perc van meg hatra? Csokkentjuk, ha vege kilepunk
   STOPAFTER=`cat mousemove.status`
   ((STOPAFTER=STOPAFTER-1))
   if [ $STOPAFTER -lt 1 ] && [ -r mousemove.run ]; then
        rm mousemove.run
   fi
   echo $STOPAFTER >mousemove.status
   sleep $DELAY
done
echo STOPPED > mousemove.status
