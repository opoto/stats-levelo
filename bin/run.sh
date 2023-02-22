#!/bin/sh

if [ "$1" != "-local" ]
then
  curl -o data/free_bike_status.json "https://api.omega.fifteen.eu/gbfs/2.2/marseille/en/free_bike_status.json?&key=MjE0ZDNmMGEtNGFkZS00M2FlLWFmMWItZGNhOTZhMWQyYzM2"
  curl -o data/station_status.json "https://api.omega.fifteen.eu/gbfs/2.2/marseille/en/station_status.json?&key=MjE0ZDNmMGEtNGFkZS00M2FlLWFmMWItZGNhOTZhMWQyYzM2"
  curl -o data/station_information.json "https://api.omega.fifteen.eu/gbfs/2.2/marseille/en/station_information.json?&key=MjE0ZDNmMGEtNGFkZS00M2FlLWFmMWItZGNhOTZhMWQyYzM2"
fi

current_month=$(date +"%Y-%m")

bikes_date=$(jq '.last_updated ' data/free_bike_status.json)
bikes_nb=$(jq '.data.bikes[].bike_id ' data/free_bike_status.json  | wc -l)
bikes_disabled=$(jq '.data.bikes[] | select (.is_disabled == true) | .bike_id' data/free_bike_status.json | wc -l)
bikes_reserved=$(jq '.data.bikes[] | select (.is_reserved == true) | .bike_id' data/free_bike_status.json | wc -l)
bikes_no_station=$(jq '.data.bikes[] | select (.is_disabled == false) | .station_id' data/free_bike_status.json | grep "\"\"" | wc -l)
bikes_for_rent=$(jq '.data.stations[] | select (.is_renting==true) | .num_bikes_available ' data/station_status.json | awk '{sum+=$0} END{print sum}')

stations_date=$(jq '.last_updated ' data/station_status.json)
stations_nb=$(jq '.data.stations[].station_id ' data/station_status.json | wc -l)
stations_renting=$(jq '.data.stations[] | select ((.is_renting==true) and (.num_bikes_available>0)) | .station_id ' data/station_status.json | wc -l)
stations_returning=$(jq '.data.stations[] | select ((.is_returning==true) and (.num_docks_available>0)) | .station_id ' data/station_status.json | wc -l)
stations_not_installed=$(jq '.data.stations[] | select (.is_installed==false) | .station_id ' data/station_status.json | wc -l)
stations_not_renting=$(jq '.data.stations[] | select (.is_renting==false) | .station_id ' data/station_status.json | wc -l)
stations_not_returning=$(jq '.data.stations[] | select (.is_returning==false) | .station_id ' data/station_status.json | wc -l)
stations_ready=$(jq '.data.stations[] | select ((.is_installed==true) and (.is_renting==true) and (.is_returning==true))| .station_id ' data/station_status.json | wc -l)

echo "BIKES"
echo Date: $(date -j -f "%s" +"%Y-%m-%d %H:%M:%S" $bikes_date)
echo Total: $bikes_nb
echo For rent: $bikes_for_rent
echo Disabled: $bikes_disabled
echo Reserved: $bikes_reserved
echo No station: $bikes_no_station
echo

echo "STATIONS"
echo Date: $(date -j -f "%s" +"%Y-%m-%d %H:%M:%S" $stations_date)
echo Total: $stations_nb
echo Ready: $stations_ready
echo Renting: $stations_renting
echo Returning: $stations_returning
echo Not installed: $stations_not_installed
echo Not renting: $stations_not_renting
echo Not returning: $stations_not_returning

if [ "$2" != "-noout" ]
then
  echo $bikes_date,$bikes_nb,$bikes_for_rent,$bikes_disabled,$bikes_reserved,$bikes_no_station>> data/${current_month}_bikes.csv
  echo $stations_date,$stations_nb,$stations_ready,$stations_renting,$stations_returning,$stations_not_installed,$stations_not_renting,$stations_not_returning>> data/${current_month}_stations.csv
fi
