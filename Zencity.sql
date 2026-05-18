select * from `bqproj-435911.zen_city.station_info`
select * from `bqproj-435911.zen_city.rentals`

--no null values in station_id--101 unique stations
select count(distinct station_id) from `bqproj-435911.zen_city.station_info`
where station_id is not null

--show status values of the sations for the entire dataa set -we have 'closed' and 'active' -we need to check the option of opening closed stations
select distinct status from `bqproj-435911.zen_city.station_info`
--closed stations
select distinct station_id, status from `bqproj-435911.zen_city.station_info`
where status='closed'
--which regions are more relevant to get more stations based on researches-collegeas-universities-travel places -parks-stadiom-musuems-center malls-tourism places
select station_id,name,sum(number_of_docks) as num_of_avbikes from `bqproj-435911.zen_city.station_info`
where location='(30.2848, -97.72756)' and location is not null 
group by station_id,name --this station should be opened because of its location

--discover another active stations, by location
select name,location,sum(number_of_docks) as num_of_bikes from `bqproj-435911.zen_city.station_info`
where status='active'
group by name,location
order by num_of_bikes desc

--converting and splitting location into 2 columns to run in python for showing in map

select name,    
    CAST(SPLIT(REPLACE(location, '(', ''), ',')[OFFSET(0)] AS FLOAT64) AS latitude,
    CAST(SPLIT(REPLACE(location, ')', ''), ',')[OFFSET(1)] AS FLOAT64) AS longitude,
    sum(number_of_docks) as num_of_bikes from `bqproj-435911.zen_city.station_info`
where status='active' and location is not null 
group by name,location
order by num_of_bikes desc
---------stations data for python----
select station_id, council_district, status,
    CAST(SPLIT(REPLACE(location, '(', ''), ',')[OFFSET(0)] AS FLOAT64) AS latitude,
    CAST(SPLIT(REPLACE(location, ')', ''), ',')[OFFSET(1)] AS FLOAT64) AS longitude,
    sum(number_of_docks) as num_of_bikes from `bqproj-435911.zen_city.station_info`
where location is not null 
group by station_id,location,council_district,status
order by num_of_bikes desc

--different id with the same name(bug in data)
select station_id, name from `bqproj-435911.zen_city.station_info`

--data about both status active and closed
select station_id, status, council_district,  
    CAST(SPLIT(REPLACE(location, '(', ''), ',')[OFFSET(0)] AS FLOAT64) AS latitude,
    CAST(SPLIT(REPLACE(location, ')', ''), ',')[OFFSET(1)] AS FLOAT64) AS longitude,
    sum(number_of_docks) as num_of_bikes,COUNT(trip_id) as popularity
     from `bqproj-435911.zen_city.station_info` info join `bqproj-435911.zen_city.rentals` rentals on rentals.start_station_id=info.station_id
    
where location is not null 
group by station_id,location,status,council_district
order by popularity desc

--number of electric bikes and classic
select bike_type, count(*) as num_bikes from(
select distinct bike_id, bike_type from `bqproj-435911.zen_city.rentals`)
group by 1

--check if there is active station with numm num_of_docks-theres no nulls
select count(*) from `bqproj-435911.zen_city.station_info`
where status='active' and number_of_docks is null
--for each station we need to check the capacity by bikes number availabloe and the number of trips made starting from these stations

with largest_stations as(
select station_id,sum(number_of_docks) as number_of_docks from `bqproj-435911.zen_city.station_info`
where status='active'
group by station_id,location
order by number_of_docks desc
)
select largest_stations.station_id,number_of_docks as number_of_docks, count(distinct rentals.trip_id) as num_of_trips from largest_stations
join `bqproj-435911.zen_city.rentals` rentals on largest_stations.station_id=rentals.start_station_id
where rentals.trip_id is not null
group by 1,2
order by 3 desc

--we need to get the stations that dont exist in the info--we have 95 stations that are in unfo but not used in rentals 
select distinct station_id from(
select t1.station_id,r.start_station_id,r.end_station_id from `bqproj-435911.zen_city.rentals` r
right join `bqproj-435911.zen_city.station_info` t1 on r.start_station_id=t1.station_id
)

where start_station_id is null
---------------------------------------------------------------
select distinct station_id,end_station_id from(
select t1.station_id,r.start_station_id,cast(r.end_station_id as int64) from `bqproj-435911.zen_city.rentals` r
right join `bqproj-435911.zen_city.station_info` t1 on r.end_station_id=t1.station_id
)

where end_station_id is null

select cast(end_station_id as int64) from `bqproj-435911.zen_city.rentals`



select distinct station_id from `bqproj-435911.zen_city.station_info` --101 stations on info
select distinct start_station_id from `bqproj-435911.zen_city.rentals` --7 stations on rentals

with rentals as(
select start_station_id, cast(end_station_id as int64) end_station_id from `bqproj-435911.zen_city.rentals`)

select info.station_id,rentals.end_station_id from `bqproj-435911.zen_city.station_info` info
left join rentals on info.station_id=rentals.end_station_id
where end_station_id is null
--we have 27 stations (exluding 0 station) that didnt appear in start neither in end stations in rentals table
with rentals as(
select start_station_id, cast(end_station_id as int64) end_station_id from `bqproj-435911.zen_city.rentals`)

select info.station_id,rentals.start_station_id,rentals.end_station_id from `bqproj-435911.zen_city.station_info` info
left join rentals on info.station_id=rentals.end_station_id
where end_station_id is null or start_station_id is null
-----check the status of the null stations on the info table
--important-there are some stations that are pointed as active in the info table but they are not in use(according to the rentals table)
with rentals as(
select start_station_id, cast(end_station_id as int64) end_station_id from `bqproj-435911.zen_city.rentals`)
select info.station_id,info.status,rentals.start_station_id,rentals.end_station_id from `bqproj-435911.zen_city.station_info` info
left join rentals on info.station_id=rentals.end_station_id
where end_station_id is null and start_station_id is null and info.status='active'

--average duration--22.06 minutes per trip
select avg(duration_minutes) from `bqproj-435911.zen_city.rentals`

--popular routes (the most is 2498 ,3798)+average duration for each route 
--1-business question: do the increase of the duration affects the popularity of the route\trip the independent is the avg_duration and the dependent is the num_of_trips
select  start_station_id, end_station_id, 
count(*) as num_of_trips,
 avg(duration_minutes) as avg_duration 
 from `bqproj-435911.zen_city.rentals`
group by 1,2
order by 3 desc
--we got in the number of trips 496 rows while when we added the subscriber type its almost 1200 rows because for each row we have different subscriber types..
select * from (
SELECT 
    start_station_id, 
    end_station_id, 
    subscriber_type,
    COUNT(*) AS num_of_trips, 
    AVG(duration_minutes) AS avg_duration
FROM `bqproj-435911.zen_city.rentals`
GROUP BY 1, 2, 3
ORDER BY num_of_trips DESC)
where start_station_id=2498 and end_station_id='3798'

--duration max/min values-we have no minuses in the duration columns 
select max(duration_minutes) from `bqproj-435911.zen_city.rentals`
select min(duration_minutes) from `bqproj-435911.zen_city.rentals`

--we have a single station which have station_id of 0 but its ointed as active station
select * from `bqproj-435911.zen_city.station_info` 
where station_id=0

--2-num of trips and subscribtion type -subscriber type could be a variable that affects the number of trips -categorial variable
select subscriber_type, count(*) as num_of_trips from `bqproj-435911.zen_city.rentals`
group by 1
order by 2 desc

--

select  start_station_id, end_station_id, subscriber_type, count(*) over(partition by subscriber_type)as num_of_trips, avg(duration_minutes) over (partition by subscriber_type)as avg_duration from `bqproj-435911.zen_city.rentals`
group by 1,2,3
order by 4 desc

--check why there are some 
select * from (
select start_station_id, FORMAT_DATE('%d-%m-%Y', start_time) as dates,trip_id from `bqproj-435911.zen_city.rentals`)
where dates='18-03-2022'
---bikes types -a variable we need to consider
select bike_type,count(*) as num_of_trips from `bqproj-435911.zen_city.rentals`
group by 1 
order by 2 desc
---------------------
with rentals as(
select start_station_id, cast(end_station_id as int64) end_station_id from `bqproj-435911.zen_city.rentals`)

select info.station_id,info.status,rentals.start_station_id,rentals.end_station_id from `bqproj-435911.zen_city.station_info` info
left join rentals on info.station_id=rentals.end_station_id
where (end_station_id is null and start_station_id is null and info.status='active') or 
(TRIM(cast(end_station_id as string))=' 'and TRIM(cast(start_station_id as string))=' ' and info.status='active')

--modified_date checking
select station_id,status,notes,modified_date from `bqproj-435911.zen_city.station_info`
where extract(year from modified_date)=2022

--is there any trip id without subscriber type
select trip_id,subscriber_type from `bqproj-435911.zen_city.rentals`
where subscriber_type is null
--
select distinct cast(end_station_id as int64) as end_stations from `bqproj-435911.zen_city.station_info` info
join `bqproj-435911.zen_city.rentals` rentals on info.station_id=cast(rentals.end_station_id as int64) 
where CAST(end_station_id AS INT64) NOT IN (
    SELECT start_station_id 
    FROM `bqproj-435911.zen_city.station_info`) and status='active'
select distinct station_id from `bqproj-435911.zen_city.station_info`
where status='active'
------------------------------Data Cleaning -----------------------------------------------------------------------------
--index time 

--the num of trips of each path using start_station and end_station
--i want for each station from the station info to display for me the number of trips was weather it appeared on start station or end station, the num of trips, and the rest data i can use cte I only need at the start to clean the data into the info then i connect the table of 

--in the common table we have 101 rows and the following quesry decreased to 81 rows
--we got 74 rows as start point for every station appeared in rentals weather it was end or start station we got 74 rows
--i used min to add more columns so that i dont have to group by the other added columns

with stations_data as(
select station_id,status,number_of_docks,council_district from `bqproj-435911.zen_city.station_info`
where station_id is not null and status is not null and number_of_docks is not null and council_district is not null)

select station_id,count(*) as num_of_trips,
MIN(stations_data.status) AS status,  
MIN(stations_data.council_district) AS council_district
from stations_data join `bqproj-435911.zen_city.rentals` rentals on stations_data.station_id=rentals.start_station_id
 or stations_data.station_id=cast(rentals.end_station_id as int64)
 group by 1
order by 2 desc


--------Data cleaning --- WE HAVE NULLS ONLY IN NUMBER OF DOCKS WE HAVE THERE 20 ROWS
SELECT 
    'station_id' AS column_name, COUNT(*) AS total_rows, 
    SUM(CASE WHEN station_id IS NULL THEN 1 ELSE 0 END) AS null_count 
FROM `bqproj-435911.zen_city.station_info` 
UNION ALL
SELECT 'name', COUNT(*), SUM(CASE WHEN name IS NULL THEN 1 ELSE 0 END) FROM `bqproj-435911.zen_city.station_info`
UNION ALL
SELECT 'status', COUNT(*), SUM(CASE WHEN status IS NULL THEN 1 ELSE 0 END) FROM `bqproj-435911.zen_city.station_info`
UNION ALL
SELECT 'location', COUNT(*), SUM(CASE WHEN location IS NULL THEN 1 ELSE 0 END) FROM `bqproj-435911.zen_city.station_info`
UNION ALL
SELECT 'NUMBER OF DOCKS', COUNT(*), SUM(CASE WHEN number_of_docks IS NULL THEN 1 ELSE 0 END) FROM `bqproj-435911.zen_city.station_info`
UNION ALL
SELECT 'COUNCIL DISTRICT', COUNT(*), SUM(CASE WHEN council_district IS NULL THEN 1 ELSE 0 END) FROM `bqproj-435911.zen_city.station_info`
-- Result: there are no null values in the 
SELECT * 
FROM `bqproj-435911.zen_city.station_info`
WHERE SAFE_CAST(footprint_length AS INT64) IS NULL AND footprint_length IS NOT NULL;
--checking duplicates in station_id--there are no duplicates in station_id
SELECT 
    station_id, 
    COUNT(*) AS occurrences
FROM 
    `bqproj-435911.zen_city.station_info`
GROUP BY 
    station_id
having occurrences>1
---------
SELECT * 
FROM `bqproj-435911.zen_city.station_info` 
WHERE SAFE_CAST(footprint_length AS INT64) IS NULL AND footprint_length IS NOT NULL;
-----NOTES COLUMN---IMPORTANT!!
SELECT NOTES,COUNT(*) FROM `bqproj-435911.zen_city.station_info` 
GROUP BY notes
-------Name-we have on name with 2 similar values
SELECT name,COUNT(*) as count_name  FROM `bqproj-435911.zen_city.station_info` 
GROUP BY name
having count_name>1
----Adress we have some repeated addresses
SELECT address,COUNT(*) as count_address FROM `bqproj-435911.zen_city.station_info` 
GROUP BY address
having count_address>1
-----------
--checking the stations numbers 111 and 1111 they are different 
select * from `bqproj-435911.zen_city.station_info` 
where station_id=111 or station_id=1111 
----------

---info_stations data cleaning 
--station_id must be with 4 digits number(we have 111 and 1111)
--make sure we don't have any null values in all columns except the number_of_docks
--make sure number of docks are not less than 0 and council_distict is more than 1 including
--make sure that we have only active or closed status 
--we got 80 rows out of 101 rows
select station_id, status,
    CAST(SPLIT(REPLACE(location, '(', ''), ',')[OFFSET(0)] AS FLOAT64) AS latitude,
    CAST(SPLIT(REPLACE(location, ')', ''), ',')[OFFSET(1)] AS FLOAT64) AS longitude,
    number_of_docks,council_district FROM `bqproj-435911.zen_city.station_info` 
where number_of_docks >=0 and (status in ('closed','active')) and station_id is not null 
and location is not null and council_district is not null and council_district>=1 and  station_id>=111--kept the number of docks with null well remove later if needed

--we have this station that we need to know the id 
select * from `bqproj-435911.zen_city.station_info`
where station_id=0
---check by location we don't have ano other station with the same location
select * from `bqproj-435911.zen_city.station_info`
where location='(30.244961, -97.751272)'

--the rentals table data cleaning
--quick check
--unique trip id numbers-we have no duplicates on trip_id
select trip_id,count(*) as count_trip_id from `bqproj-435911.zen_city.rentals`
group by trip_id
having count_trip_id>1

--showing null values
SELECT 
    'trip_id' AS column_name, COUNT(*) AS total_rows, 
    SUM(CASE WHEN trip_id IS NULL THEN 1 ELSE 0 END) AS null_count 
FROM `bqproj-435911.zen_city.rentals`
UNION ALL
SELECT 'subscriber type', COUNT(*), SUM(CASE WHEN subscriber_type IS NULL THEN 1 ELSE 0 END) FROM `bqproj-435911.zen_city.rentals`
UNION ALL
SELECT 'bike_id', COUNT(*), SUM(CASE WHEN bike_id IS NULL THEN 1 ELSE 0 END) FROM `bqproj-435911.zen_city.rentals`
UNION ALL
SELECT 'bike_type', COUNT(*), SUM(CASE WHEN bike_type IS NULL THEN 1 ELSE 0 END) FROM `bqproj-435911.zen_city.rentals`
UNION ALL
SELECT 'start_time', COUNT(*), SUM(CASE WHEN start_time IS NULL THEN 1 ELSE 0 END) FROM `bqproj-435911.zen_city.rentals`
UNION ALL
SELECT 'start_station_id', COUNT(*), SUM(CASE WHEN start_station_id IS NULL THEN 1 ELSE 0 END) FROM `bqproj-435911.zen_city.rentals`
UNION ALL
SELECT 'end_station_id', COUNT(*), SUM(CASE WHEN end_station_id IS NULL THEN 1 ELSE 0 END) FROM `bqproj-435911.zen_city.rentals`
UNION ALL
SELECT 'duration', COUNT(*), SUM(CASE WHEN duration_minutes IS NULL THEN 1 ELSE 0 END) FROM `bqproj-435911.zen_city.rentals`
-- Result: we have null value only in end station, we need to see that: its on trip_id=26160487
select * from `bqproj-435911.zen_city.rentals`
where end_station_id is null

--checking the duration
select max(duration_minutes)   as max_duration from `bqproj-435911.zen_city.rentals`
union all
select min(duration_minutes) as min_duration from `bqproj-435911.zen_city.rentals`
---check if there any durations>1000-we need to check what to do with  them
select duration_minutes from  `bqproj-435911.zen_city.rentals` 
where duration_minutes>=1000

---check start time-the date doesnt have outliers // checked 
select distinct extract(year from start_time), count(*) from  `bqproj-435911.zen_city.rentals`
where extract(year from start_time)!=2022
select distinct extract(month from start_time) ,count(*) from  `bqproj-435911.zen_city.rentals`
where  extract(month from start_time) <1 and extract(month from start_time) >12
select distinct extract(day from start_time) as day, count(*) from  `bqproj-435911.zen_city.rentals` 
where extract(day from start_time)>31 and extract(day from start_time)<1

--we need to check the srart station id and end station id-as we see before there are no null values here
select start_station_id, count(*) from `bqproj-435911.zen_city.rentals` 
group by start_station_id

select end_station_id, count(*) from `bqproj-435911.zen_city.rentals` 
group by end_station_id
--rows duplicates -there are no row duplicates 
SELECT *, COUNT(*) AS occurrences
FROM `bqproj-435911.zen_city.rentals` 
GROUP BY trip_id, subscriber_type, bike_id, bike_type, start_time, start_station_id, 
        start_station_name, end_station_id, end_station_name, duration_minutes
HAVING COUNT(*) > 1;
--final rental table down from 10780 rows to 10779 rows 
select trip_id, subscriber_type, bike_id, bike_type, start_time, start_station_id, 
        start_station_name, end_station_id, end_station_name, duration_minutes
        from `bqproj-435911.zen_city.rentals` 
        where trip_id is not null and subscriber_type is not null and bike_id is not null and bike_type in ('electric','classic') and 
        extract(year from start_time)=2022 and extract(month from start_time) >=1 and extract(month from start_time) <=12
        and extract(day from start_time)<=31 and extract(day from start_time)>=1 and start_time is not null and start_station_id is not null
        and end_station_id is not null and duration_minutes is not null

---final data cleanining table for analysis -got 8275 rows 
with stations_info_updated as (
    select station_id, status,
    CAST(SPLIT(REPLACE(location, '(', ''), ',')[OFFSET(0)] AS FLOAT64) AS latitude,
    CAST(SPLIT(REPLACE(location, ')', ''), ',')[OFFSET(1)] AS FLOAT64) AS longitude,
    number_of_docks,council_district FROM `bqproj-435911.zen_city.station_info` 
where number_of_docks >=0 and (status in ('closed','active')) and station_id is not null 
and location is not null and council_district is not null and council_district>=1 and  station_id>=111
),

rentals_updated as(
    select trip_id, subscriber_type, bike_id, bike_type, start_time, start_station_id, 
        start_station_name, cast(end_station_id as int64) as end_station_id, end_station_name, duration_minutes
        from `bqproj-435911.zen_city.rentals` 
        where trip_id is not null and subscriber_type is not null and bike_id is not null and bike_type in ('electric','classic') and 
        extract(year from start_time)=2022 and extract(month from start_time) >=1 and extract(month from start_time) <=12
        and extract(day from start_time)<=31 and extract(day from start_time)>=1 and start_time is not null and start_station_id is not null
        and end_station_id is not null and duration_minutes is not null
)

select rentals_updated.*,stations_info_updated.*, EXTRACT(MONTH FROM start_time) as month, 
FORMAT_TIMESTAMP('%A', start_time) AS day_of_week,
 COUNT(trip_id) OVER (PARTITION BY start_station_id) AS trips_per_start_station,
    COUNT(trip_id) OVER (PARTITION BY end_station_id) AS trips_per_end_station,
    COUNT(trip_id) OVER (PARTITION BY start_station_id, subscriber_type) AS trips_per_station_and_user_type,
    COUNT(trip_id) OVER (PARTITION BY bike_type) AS trips_per_bike_type,
    COUNT(trip_id) OVER (PARTITION BY EXTRACT(MONTH FROM start_time)) AS trips_per_month

  from rentals_updated 
join stations_info_updated on 
rentals_updated.end_station_id=stations_info_updated.station_id
join stations_info_updated stations2 on rentals_updated.start_station_id=stations2.station_id
order by 5 desc

---WHAT WE HAVE AND WHAT WE DON'T HAVE IN OUR DATA

with stations_info_cleaned as 
(select 
  distinct station_id, 
  status,
  number_of_docks,
  council_district 
FROM `bqproj-435911.zen_city.station_info` 
where number_of_docks >=0 or number_of_docks is null
and (status in ('closed','active')) 
and station_id is not null 
and location is not null 
and council_district is not null 
and council_district>=1), 

rentals_cleaned as
(select 
  distinct trip_id, 
  subscriber_type, 
  bike_id, 
  bike_type, 
  start_time, 
  start_station_id, 
  start_station_name, 
  cast(end_station_id as int64) as end_station_id, 
  end_station_name, 
  duration_minutes
from `bqproj-435911.zen_city.rentals` 
where trip_id is not null 
and subscriber_type is not null 
and bike_id is not null 
and bike_type in ('electric','classic') 
and extract(year from start_time)=2022 
and extract(month from start_time) >=1 
and extract(month from start_time) <=12
and extract(day from start_time)<=31 
and extract(day from start_time)>=1 
and start_time is not null 
and start_station_id is not null
and end_station_id is not null 
and duration_minutes is not null),
cleaned_data as (select 
  r.*,
  s1.*, 
  EXTRACT(MONTH FROM start_time) as month, 
  FORMAT_TIMESTAMP('%A', start_time) AS day_of_week,

from rentals_cleaned r
join stations_info_cleaned s1
on r.end_station_id = s1.station_id
join stations_info_cleaned s2 
on r.start_station_id = s2.station_id)

select council_district,count(distinct station_id) as number_of_stations, count(trip_id) as num_of_rentals from stations_info_cleaned s left join rentals_cleaned r
on r.start_station_id=s.station_id
group by 1