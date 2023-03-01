#!/bin/sh

if [ "$1" != "-local" ]
then
  #curl -o data/free_bike_status.json "https://api.omega.fifteen.eu/gbfs/2.2/marseille/en/free_bike_status.json?&key=MjE0ZDNmMGEtNGFkZS00M2FlLWFmMWItZGNhOTZhMWQyYzM2"
  #curl -o data/station_status.json "https://api.omega.fifteen.eu/gbfs/2.2/marseille/en/station_status.json?&key=MjE0ZDNmMGEtNGFkZS00M2FlLWFmMWItZGNhOTZhMWQyYzM2"
  #curl -o data/station_information.json "https://api.omega.fifteen.eu/gbfs/2.2/marseille/en/station_information.json?&key=MjE0ZDNmMGEtNGFkZS00M2FlLWFmMWItZGNhOTZhMWQyYzM2"
fi

current_year=$(date +"%Y")
current_month=$(date +"%Y-%m")
current_hour=$(date +"%H")
AVG_HOUR=23

bikes_date=$(jq '.last_updated ' data/free_bike_status.json)
bikes_nb=$(jq '.data.bikes[].bike_id ' data/free_bike_status.json  | wc -l)
bikes_disabled=$(jq '.data.bikes[] | select (.is_disabled == true) | .bike_id' data/free_bike_status.json | wc -l)
bikes_reserved=$(jq '.data.bikes[] | select (.is_reserved == true) | .bike_id' data/free_bike_status.json | wc -l)
bikes_no_station=$(jq '.data.bikes[] | select ((.is_disabled == false) and (.station_id == "")) | .station_id' data/free_bike_status.json | wc -l)
bikes_for_rent=$(jq '.data.stations[] | select (.is_renting==true) | .num_bikes_available ' data/station_status.json | awk '{sum+=$0} END{print sum}')

stations_date=$(jq '.last_updated ' data/station_status.json)
stations_nb=$(jq '.data.stations[].station_id ' data/station_status.json | wc -l)
stations_renting=$(jq '.data.stations[] | select ((.is_installed==true) and (.is_renting==true) and (.num_bikes_available>0)) | .station_id ' data/station_status.json | wc -l)
stations_returning=$(jq '.data.stations[] | select ((.is_installed==true) and (.is_returning==true) and (.num_docks_available>0)) | .station_id ' data/station_status.json | wc -l)
stations_not_installed=$(jq '.data.stations[] | select (.is_installed==false) | .station_id ' data/station_status.json | wc -l)
stations_not_renting=$(jq '.data.stations[] | select (.is_renting==false) | .station_id ' data/station_status.json | wc -l)
stations_not_returning=$(jq '.data.stations[] | select (.is_returning==false) | .station_id ' data/station_status.json | wc -l)
stations_ready=$(jq '.data.stations[] | select ((.is_installed==true) and (.is_renting==true) and (.is_returning==true))| .station_id ' data/station_status.json | wc -l)

echo Current hour: $current_hour
echo

echo "BIKES"
echo Date: $(date -d @$bikes_date)
echo Total: $bikes_nb
echo For rent: $bikes_for_rent
echo Disabled: $bikes_disabled
echo Reserved: $bikes_reserved
echo No station: $bikes_no_station
echo

echo "STATIONS"
echo Date: $(date -d @$stations_date)
echo Total: $stations_nb
echo Ready: $stations_ready
echo Renting: $stations_renting
echo Returning: $stations_returning
echo Not installed: $stations_not_installed
echo Not renting: $stations_not_renting
echo Not returning: $stations_not_returning

bikes_month_csv=data/${current_month}_bikes.csv
stations_month_csv=data/${current_month}_stations.csv
bikes_year_csv=data/${current_year}_bikes.csv
stations_year_csv=data/${current_year}_stations.csv

gitmsg=""

create_if_missing () {
  if [ ! -f ${1} ]
  then
    echo ${3} > ${1}
    git add ${1}
    gitmsg="${gitmsg}New ${2}. "
  fi
}

if [ "$2" != "-noout" ]
then
  git config --local user.email "github-actions[bot]@users.noreply.github.com"
  git config --local user.name "github-actions[bot]"

  create_if_missing ${bikes_month_csv} "month" "date,bikes_nb,for_rent,disabled,reserved,no_station"
  echo $bikes_date,$bikes_nb,$bikes_for_rent,$bikes_disabled,$bikes_reserved,$bikes_no_station>> ${bikes_month_csv}

  create_if_missing ${stations_month_csv} "month" "date,stations_nb,ready,renting,returning,not_installed,not_renting,not_returning"
  echo $stations_date,$stations_nb,$stations_ready,$stations_renting,$stations_returning,$stations_not_installed,$stations_not_renting,$stations_not_returning>> ${stations_month_csv}

echo  "is $current_hour  == $AVG_HOUR?"
  if [ "$current_hour" == "$AVG_HOUR" ]
  then
    create_if_missing ${bikes_year_csv} "year" "date,bikes_nb,for_rent,disabled,reserved,no_station"
    nlines=$(cat ${bikes_month_csv} | wc -l)
    # skip header line if less then 24 lines
    nlines=$((nlines<25 ? nlines-1 : 24))
    echo "averaging $nlines lines"
    tail -n ${nlines} ${bikes_month_csv} | awk -F',' '{ c1=$1; c2+=$2; c3+=$3; c4+=$4; c5+=$5;c6+=$6} END {print c1","int(c2/NR)","int(c3/NR)","int(c4/NR)","int(c5/NR)","int(c6/NR)}' >> ${bikes_year_csv}

    create_if_missing ${stations_year_csv} "year" "date,stations_nb,ready,renting,returning,not_installed,not_renting,not_returning"
    tail -n ${nlines} ${stations_month_csv} | awk -F',' '{ c1=$1; c2+=$2; c3+=$3; c4+=$4; c5+=$5;c6+=$6; c7+=$7;c8+=$8} END {print c1","int(c2/NR)","int(c3/NR)","int(c4/NR)","int(c5/NR)","int(c6/NR)","int(c7/NR)","int(c8/NR)}' >> ${stations_year_csv}
  fi

  #git commit -a -m "${gitmsg}Data updated"
  #git push
fi
