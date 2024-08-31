create database hospitality;
use hospitality;
desc dim_date;
select * from dim_date;

-- Data Cleaning
alter table dim_date
modify date date, modify mmm_yy varchar(255), modify week_no varchar(255),modify day_type varchar(255);
update dim_date
set date=str_to_date(date,"%d-%M-%Y");
/*update dim_date
set mmm_yy=date_format(mmm_yy,"%b-%y");*/

desc dim_hotels;
select * from dim_hotels;
alter table dim_hotels
modify property_name varchar(255), modify category varchar(255),modify city varchar(255);

desc dim_rooms;
select * from dim_rooms;

desc fact_aggregated_bookings;
select * from fact_aggregated_bookings;
alter table fact_aggregated_bookings
modify check_in_date date, modify room_category varchar(25);
update fact_aggregated_bookings
set check_in_date=str_to_date(check_in_date,"%d-%M-%Y");

desc fact_bookings;
select * from fact_bookings;
alter table fact_bookings
modify booking_id varchar(25),modify property_id int, modify booking_date date, modify check_in_date date, modify checkout_date date,modify no_guests int, modify room_category varchar(25), modify booking_platform varchar(25), modify ratings_given int, modify booking_status varchar(25), modify revenue_generated int, modify revenue_realized int;
select * from fact_bookings where ratings_given = '';
update fact_bookings
set ratings_given = null
where ratings_given = '';
select * from fact_bookings where ratings_given = null;

-- KPI's
-- 1) Total Revenue
select concat(round(sum(revenue_realized)/1000000000,2), ' B') as Total_Revenue 
from fact_bookings;

-- 2) Occupancy Percentage
select concat(round((sum(successful_bookings)/sum(capacity))*100,2), ' %') as Occupancy_Percentage 
from fact_aggregated_bookings;

-- 3) Total Booking
select concat(round(count(booking_id)/1000),' k') total_bookings from fact_bookings;

-- 4) Cancellation Percentage
select concat(round((fb1.total_booking_cancelled/fb2.total_bookings) * 100,2),' %') as 'Cancellation_%'
from (select count(booking_id) total_booking_cancelled from fact_bookings where booking_status = 'Cancelled') as fb1,
(select count(booking_id) total_bookings from fact_bookings) as fb2;

-- 5)Total Capacity
select concat(round(sum(capacity)/1000),' k') Total_Capacity 
from fact_aggregated_bookings;

-- Visuals
-- 1) Revenue
-- Class wise revenue
select dr.room_class, concat(round(sum(fb.revenue_realized)/1000000), ' M') as revenue,
concat(round((sum(fb.revenue_realized)/(select sum(revenue_realized) from fact_bookings))*100,2),' %') as revenue_percentage
from dim_rooms dr join fact_bookings fb
on dr.room_id = fb.room_category
group by dr.room_class;

-- Revenue by Month
select dm.mmm_yy as Months, concat(round(sum(fb.revenue_realized)/1000000), ' M') as revenue
from dim_date dm join fact_bookings fb
on dm.date = fb.check_in_date
group by dm.mmm_yy;

-- Revenue by City
select dh.city, concat(round(sum(fb.revenue_realized)/1000000), ' M') as revenue
from dim_hotels dh join fact_bookings fb
on dh.property_id = fb.property_id
group by dh.city
order by revenue desc;

-- Hotel wise Revenue
select dh.property_name, concat(round(sum(fb.revenue_realized)/1000000,0),' M') as revenue
from dim_hotels dh join fact_bookings fb
on dh.property_id = fb.property_id
group by dh.property_name
order by revenue desc;

-- Revenue by Booking Platform
select booking_platform, concat(round(sum(revenue_realized)/1000000,0),'M') as revenue
from fact_bookings
group by booking_platform
order by revenue desc;

-- 2) Booking
-- Total Bookings by Booking Platform 
select booking_platform, concat(round(count(booking_id)/1000),' K') Total_Bookings
from fact_bookings
group by booking_platform
order by Total_Bookings desc;

-- Class wise Total Bookings
select dr.room_class, concat(round(count(fb.booking_id)/1000),' K') Total_Bookings
from dim_rooms dr join fact_bookings fb
on dr.room_id = fb.room_category
group by dr.room_class
order by Total_Bookings desc;

-- City wise Total Bookings
select dh.city, concat(round(count(fb.booking_id)/1000),' K') Total_Bookings
from dim_hotels dh join fact_bookings fb
on dh.property_id = fb.property_id
group by dh.city
order by Total_Bookings desc;

 -- Total Checked Out, Total cancelled bookings and Total no show bookings by city
select dh.city,
sum(case when fb.booking_status = 'Checked Out' then 1 end) Total_Checked_Out,
sum(case when fb.booking_status = 'Cancelled' then 1 end) Total_Cancelled,
sum(case when fb.booking_status = 'No Show' then 1 end) Total_No_Show,
count(fb.booking_id) Total_Bookings
from dim_hotels dh join fact_bookings fb
on dh.property_id = fb.property_id
group by dh.city
order by Total_Bookings desc;

-- Weekly Trend of Total Bookings
select dd.week_no Weekly_Trend, count(fb.booking_id) Total_Bookings
from dim_date dd join fact_bookings fb
on dd.date = fb.check_in_date
group by dd.week_no
order by Total_Bookings desc;

-- 3) Occupancy
-- Week wise Occupancy %
select dd.week_no Weekly_Trend, concat(round((sum(successful_bookings)/sum(capacity))*100,2), ' %') as Occupancy_Percentage
from dim_date dd join fact_aggregated_bookings fab
on dd.date = fab.check_in_date
group by dd.week_no
order by Occupancy_Percentage desc;

-- City wise Capacity and Successful Bookings 
select dh.city, sum(capacity) Capacity, sum(successful_bookings) Successful_Bookings
from dim_hotels dh join fact_aggregated_bookings fab
on dh.property_id = fab.property_id
group by dh.city
order by Capacity desc;

-- Class wise Capacity and Successful Bookings 
select dr.room_class, sum(capacity) Capacity, sum(successful_bookings) Successful_Bookings
from dim_rooms dr join fact_aggregated_bookings fab
on dr.room_id = fab.room_category
group by dr.room_class
order by Capacity desc;

-- Week wise Capacity and Successful Bookings
select dd.week_no as Week, sum(capacity) Capacity, sum(successful_bookings) Successful_Bookings
from dim_date dd join fact_aggregated_bookings fab
on dd.date = fab.check_in_date
group by dd.week_no
order by Capacity desc;



