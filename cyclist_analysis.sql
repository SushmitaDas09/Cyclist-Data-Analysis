--create temp table
create table #google_data(ride_id varchar(255), rideable_type varchar(255), started_at datetime, 
ended_at datetime, start_lat float, start_lng float, end_lat float, end_lng float, member_casual nvarchar(255))
--Insert data into temp table
insert into #google_data
select ride_id, rideable_type, started_at, ended_at, start_lat, start_lng, end_lat, end_lng, member_casual
from April2020
union
select ride_id, rideable_type, started_at, ended_at, start_lat, start_lng, end_lat, end_lng, member_casual
from May2020
union
select ride_id, rideable_type, started_at, ended_at, start_lat, start_lng, end_lat, end_lng, member_casual
from June2020
union
select ride_id, rideable_type, started_at, ended_at, start_lat, start_lng, end_lat, end_lng, member_casual
from July2020
union
select ride_id, rideable_type, started_at, ended_at, start_lat, start_lng, end_lat, end_lng, member_casual
from August2020
union
select ride_id, rideable_type, started_at, ended_at, start_lat, start_lng, end_lat, end_lng, member_casual
from September2020
union
select ride_id, rideable_type, started_at, ended_at, start_lat, start_lng, end_lat, end_lng, member_casual
from October2020
union
select ride_id, rideable_type, started_at, ended_at, start_lat, start_lng, end_lat, end_lng, member_casual
from November2020
union
select ride_id, rideable_type, started_at, ended_at, start_lat, start_lng, end_lat, end_lng, member_casual
from December2020
union
select ride_id, rideable_type, started_at, ended_at, start_lat, start_lng, end_lat, end_lng, member_casual
from Jan2021
union
select ride_id, rideable_type, started_at, ended_at, start_lat, start_lng, end_lat, end_lng, member_casual
from Feb2021
union
select ride_id, rideable_type, started_at, ended_at, start_lat, start_lng, end_lat, end_lng, member_casual
from March2021
union
select ride_id, rideable_type, started_at, ended_at, start_lat, start_lng, end_lat, end_lng, member_casual
from April2021
--Let's view temp table
select* from #google_data

-- create new columns
ALTER TABLE #google_data
ADD start_date date, start_time time, end_date date, end_time time, date_diff int,  
day_name varchar(50),ride_time varchar(50)
-- add data to new columns
UPDATE #google_data
SET start_date = cast(started_at as date), start_time = cast(started_at as time),
end_date = cast(ended_at as date), end_time = cast(ended_at as time),
date_diff = DATEDIFF(DAY, start_date, end_date), day_name = datename(dw,started_at),
ride_time = CONVERT(VARCHAR(10), start_time, 0) 
--columns date_diff and ride_time had null values as they use columns that didnt exist before so had to update again
update #google_data
set date_diff = DATEDIFF(DAY, start_date, end_date), ride_time = CONVERT(VARCHAR(10), start_time, 0)

--create a column for month
alter table #google_data add month_name nvarchar(255)
update #google_data
set month_name = datename(month,start_date) 

--create a column for season
alter table #google_data
add season as (case when month_name in ('December','January','February') then 'Winter'
when month_name in ('June','July','August') then 'Summer'
when month_name in ('September', 'October', 'November') then 'Fall'
else 'Spring' end )

--add column ride_length
alter table #google_data
add ride_length_mins int
update #google_data
set ride_length_mins = datediff(minute, started_at, ended_at)

--add column office_hours
alter table #google_data
add office_hours as (case when start_time between '8:00:00' and '11:00:00' and day_name not in ('Saturday','Sunday')
then 'Yes'
else 'No' end )

-- Let's start analyzing
select * from #google_data
 
 --first observation (member's go on a ride more than casuals)
 select member_casual, count(*) as total_count from #google_data
 group by member_casual
 order by total_count desc

 --second observation(The average ride_length_mins of casuals more than members)
 select member_casual, avg(ride_length_mins) as avg_ride_length_mins from #google_data
 group by member_casual
 order by avg_ride_length_mins desc

 --third observation (which day_name members and casuals prefer)
 select member_casual, day_name, count(member_casual) as total_count from #google_data
 group by member_casual, day_name
 order by total_count desc

 --fourth observation(fraction of ride on each day_name)
 --for members
 select member_casual, day_name,
(count(member_casual)*100.0 /(select count(*) from #google_data where member_casual = 'member'))
 as fraction from #google_data
 where member_casual = 'member'
 group by member_casual, day_name
 order by fraction desc
 --for casuals
  select member_casual, day_name,
(count(member_casual)*100.0 /(select count(*) from #google_data where member_casual = 'casual'))
 as fraction from #google_data
 where member_casual = 'casual'
 group by member_casual, day_name
 order by fraction desc

 --fifth observation 
 select member_casual, count(member_casual) as total_office_users from #google_data
 where office_hours = 'Yes'
 group by member_casual
 order by total_office_users desc

 --sixth observation(fraction of users)
 -- for members
 select (count(member_casual)*100.0/(select count(*) from #google_data where member_casual = 'member'))
 as fraction_office_users from #google_data
 where office_hours = 'Yes' and member_casual = 'member'
 -- for casuals
 select (count(member_casual)*100.0/(select count(*) from #google_data where member_casual = 'casual'))
 as fraction_office_users from #google_data
 where office_hours = 'Yes' and member_casual = 'casual'

-- seventh observation (season)
select season, member_casual, count(*) as total_count from #google_data
group by season, member_casual
order by total_count desc

-- eight observation (bike types)
select rideable_type, member_casual, count(member_casual) as total_count from #google_data
group by rideable_type, member_casual
order by total_count desc

 --ninth observation (type of season affecting bike types)
 select rideable_type, member_casual, season, count(member_casual) as total_count from #google_data
group by rideable_type, member_casual,season
order by total_count desc

--tenth observation
select ride_time, member_casual, count(member_casual) as total_count from #google_data
group by ride_time, member_casual
order by ride_time

--eleventh observation
select month_name, member_casual, count(*) as total_count from #google_data
group by month_name, member_casual
order by total_count desc
