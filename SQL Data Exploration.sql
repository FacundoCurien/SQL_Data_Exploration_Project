/*

SQL EXPLORATION PROJECT

Skills used: Numeric functions, Case, Convert datatypes, Date functions, Joins, CTEs, Max-Min, Temp Tables, Database functions (CREATE, ALTER, DROP),
             Top, Stored Procedure, Views, Subqueries.

Customer profile analysis, features of the most chosen trips and attributes of the best sellers.

*/

-------------------------------------------------------------------------------------------------------------------------------

-- TABLES USED

select * from CLIENT

select * from [HOLIDAY PACKAGE]

select * from PAYMENT

select * from SELLER

select * from TRAVEL

-------------------------------------------------------------------------------------------------------------------------------

-- CUSTOMERS
-- (Let's get to know about the customers that buy the product)

-- Age of customers

select Age_Client, COUNT(Age_Client) as Count_Age_Client
from CLIENT
where Prod_Taken = 1
group by Age_Client
order by 2 desc;


-- Marital status of customers. Let's group it into "Married" or "Single"

with Marital_Status_new as(
select Marital_Status, prod_taken, 
       (case when Marital_Status = 'Unmarried' then 'Single'
	        when Marital_Status = 'Divorced' then 'Single'
			else Marital_Status
	        end) as Marital_edited 
from CLIENT
)
select Marital_edited,COUNT(Marital_edited) as Count_Marital_edited
from Marital_Status_new
where Prod_Taken = 1
group by Marital_edited
order by 2 desc;


-- Gender of customers

select Gender, COUNT(Gender) as Count_Gender, Convert(Decimal(255),COUNT(Gender)*1.0/(select COUNT(Gender) from CLIENT where Prod_Taken = 1)*100,0) as Percentage_of_Total
from CLIENT
where Prod_Taken = 1
group by Gender
order by 2 desc;


-- Level of income of customers. For this we gonna split our customers into three categories according to their level of income.

with Income_Categories as(
select Monthly_Income, Prod_Taken,
	(case when [Monthly_Income ] < 20485 then 'First Category'
		 when [Monthly_Income ] > 20485 and [Monthly_Income ] < 30000 then 'Second Category'
		 when [Monthly_Income ] > 30000 then 'Third Category'
		 end) as Category 
from CLIENT
)
select Category, COUNT(Category) as Count_Category
from Income_Categories
where Prod_Taken = 1
group by Category
order by 2 desc;


-------------------------------------------------------------------------------------------------------------------------------

-- TRAVEL
-- (Let's analyze the travel chosen of our customers)

-- Top 3 months to travel according to the number of trips of all customers.

select *
from TRAVEL

select TOP 3 YEAR(travel_date) as Year, MONTH(travel_date) as Month_number, Datename(MONTH,travel_date) as Month_name , COUNT (id_travel) as Number_of_trips
from TRAVEL
group by YEAR(travel_date), MONTH(travel_date), Datename(MONTH,travel_date)
order by 4 desc;


--	The products chosen by the customers and the percentage out of the total.

select *
from [HOLIDAY PACKAGE]

select H.Product, H.[Cost ], COUNT(H.Product) AS 'N of clients', CONVERT(decimal(255),COUNT(H.Product)*1.0/(select COUNT(id_client) from CLIENT)*100,0) as Percentage_of_Total
from TRAVEL T
left join [HOLIDAY PACKAGE] H
on T.Id_Package = H.Id_Package
GROUP BY H.Product, H.[Cost ]
order by 3 desc;


-- Customer's kind of trip. For this we gonna split our customers into three categories.

with Travel2 as(
select Number_of_persons, Number_Of_Children, 
	(case when Number_Of_Children > 0 then 'Family Trip'
	     when Number_Of_Persons = 1 then 'Individual Trip'
		 else 'Other Trip'
		 end) as Type_of_trip
from TRAVEL
)
select Type_of_trip, COUNT(Type_of_trip) as Number_of_trips
from travel2
group by Type_of_trip
order by 2 desc;


-- Most chosen country to travel.

with N_trips_Country 
as(
select country, COUNT(country) as N_Trips
from TRAVEL
group by Country)
select country as 'Most chosen country', N_Trips
from N_trips_Country
where N_Trips = (select MAX(N_Trips) from N_trips_Country);


-- Least chosen country to travel.

with N_trips_Country 
as(
select country, COUNT(country) as N_Trips
from TRAVEL
group by Country)
select country as 'Least chosen country', N_Trips
from N_trips_Country
where N_Trips = (select MIN(N_Trips) from N_trips_Country);



-------------------------------------------------------------------------------------------------------------------------------

-- SELLER
-- (Let's analyze the most successful sellers)

-- Let's create a SUCCESS RATE as the percentage of customers who bought the product, out of the total number of customers contacted.

select *
from CLIENT

select *
from SELLER

with Existing_Customers 
as(
select COUNT(id_client) as N_Existing_Customers
from CLIENT
where Prod_Taken = 1)
select N_Existing_Customers*1.0/(select COUNT(id_client) from CLIENT)*100 as 'Total Success Rate'
from Existing_Customers;


--Top 10 sellers (according to their success rate)

with N_Contacted as(
select S.Id_Seller, S.Last_name_Seller, COUNT(id_client) as N_Cust_Cont
from CLIENT C
left join SELLER S
ON C.Id_Seller = S.Id_Seller
group by S.Id_Seller, S.Last_name_Seller),
	N_Existing as(
select S.Id_Seller, S.Last_name_Seller, COUNT(id_client) as N_Existing_Customer
from CLIENT C
left join SELLER S
ON C.Id_Seller = S.Id_Seller
where Prod_taken = 1
group by S.Id_Seller, S.Last_name_Seller)
select TOP 10 N_Contacted.Id_Seller, N_Contacted.Last_name_Seller, N_Existing_Customer*1.0/N_Cust_Cont*100 as 'Success Rate'
from N_Contacted
left join N_Existing
on N_Contacted.Id_Seller = N_Existing.Id_Seller
order by 3 desc;


-- Let's create a TEMP TABLE from the table above and add more info. about the sellers

DROP TABLE if exists #Sellers_Success_Rate
CREATE TABLE #Sellers_Success_Rate (
Id_Seller nvarchar(255),
Last_name_seller nvarchar(255),
Age_Seller nvarchar(255),
Seniority_in_company nvarchar(255),
Gender text,
Nationality text,
Success_Rate decimal(10,2));


-- Let's add the info.

with N_Contacted 
	as(
select S.Id_Seller, S.Last_name_Seller, S.Age_Seller, S.[Seniority_in_company ], S.Gender, S.Nationality ,COUNT(id_client) as N_Cust_Cont
from CLIENT C
left join SELLER S
ON C.Id_Seller = S.Id_Seller
group by S.Id_Seller, S.Last_name_Seller, S.Age_Seller, S.[Seniority_in_company ], S.Gender, S.Nationality
),
	N_Existing 
	as(
select S.Id_Seller, S.Last_name_Seller, COUNT(id_client) as N_Existing_Customer
from CLIENT C
left join SELLER S
ON C.Id_Seller = S.Id_Seller
where Prod_taken = 1
group by S.Id_Seller, S.Last_name_Seller
)
INSERT INTO #Sellers_Success_Rate
select N_Contacted.Id_Seller, N_Contacted.Last_name_Seller, N_Contacted.Age_Seller, N_Contacted.Seniority_in_company, N_Contacted.Gender, N_Contacted.Nationality 
,N_Existing_Customer*1.0/N_Cust_Cont*100 as 'Success Rate'
from N_Contacted
left join N_Existing
on N_Contacted.Id_Seller = N_Existing.Id_Seller
order by 3 desc;

select *
from #Sellers_Success_Rate
order by Success_Rate desc;


-- Age of the top 10 sellers? (according to their success rate)

select TOP 10 Age_Seller, Success_Rate
from #Sellers_Success_Rate
order by Success_Rate desc;


-- Sellers with more sales

select S.Id_Seller, S.Last_name_Seller, SUM(P.Cost) as Sales
from CLIENT C
left join TRAVEL T
on C.Id_Client =T.Id_Client
left join SELLER S
on C.Id_Seller = S.Id_Seller
left join PAYMENT P
ON P.Id_Client = C.Id_Client
group by S.Id_Seller, S.Last_name_Seller
order by 3 desc;


-- Most successful Pitchs duration (according to their success rate)

select *
from #Sellers_Success_Rate
order by Success_Rate desc;

select *
from CLIENT

select C.Duration_Of_Pitch, avg(SR.Success_Rate) as Avg_Success_Rate
from CLIENT C
left join #Sellers_Success_Rate SR
on C.Id_Seller = SR.Id_Seller
group by C.Duration_Of_Pitch
order by 2 desc;


-- Let's create a STORED PROCEDURE to query the performance of the seller wanted by specifying the last name.

CREATE PROCEDURE Seller_Performance
as
select *
from #Sellers_Success_Rate

EXEC Seller_Performance @Last_Name_Seller = 'CAMPBELL'


-------------------------------------------------------------------------------------------------------------------------------

-- VIEWS
-- (Let's create some views to store useful data)

-- View for CUSTOMERS

CREATE VIEW Income_Categories as
with Income_Categories as(
select Monthly_Income, Prod_Taken,
	(case when [Monthly_Income ] < 20485 then 'First Category'
		 when [Monthly_Income ] > 20485 and [Monthly_Income ] < 30000 then 'Second Category'
		 when [Monthly_Income ] > 30000 then 'Third Category'
		 end) as Category 
from CLIENT
)
select Category, COUNT(Category) as Count_Category
from Income_Categories
where Prod_Taken = 1
group by Category;


-- View for TRAVEL

CREATE VIEW Kind_of_Trip as
with Travel2 as(
select Number_of_persons, Number_Of_Children, 
	(case when Number_Of_Children > 0 then 'Family Trip'
	     when Number_Of_Persons = 1 then 'Individual Trip'
		 else 'Other Trip'
		 end) as Type_of_trip
from TRAVEL
)
select Type_of_trip, COUNT(Type_of_trip) as Number_of_trips
from travel2
group by Type_of_trip;


-- View for SELLERS

CREATE VIEW Sellers_Success_Rate as
with N_Contacted 
	as(
select S.Id_Seller, S.Last_name_Seller, S.Age_Seller, S.[Seniority_in_company ], S.Gender, S.Nationality ,COUNT(id_client) as N_Cust_Cont
from CLIENT C
left join SELLER S
ON C.Id_Seller = S.Id_Seller
group by S.Id_Seller, S.Last_name_Seller, S.Age_Seller, S.[Seniority_in_company ], S.Gender, S.Nationality
),
	N_Existing 
	as(
select S.Id_Seller, S.Last_name_Seller, COUNT(id_client) as N_Existing_Customer
from CLIENT C
left join SELLER S
ON C.Id_Seller = S.Id_Seller
where Prod_taken = 1
group by S.Id_Seller, S.Last_name_Seller
)
select N_Contacted.Id_Seller, N_Contacted.Last_name_Seller, N_Contacted.Age_Seller, N_Contacted.Seniority_in_company, N_Contacted.Gender, N_Contacted.Nationality 
,N_Existing_Customer*1.0/N_Cust_Cont*100 as 'Success Rate'
from N_Contacted
left join N_Existing
on N_Contacted.Id_Seller = N_Existing.Id_Seller;






-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------


