/* You're a Data Analyst for a Hotel Group and received a historical database of the revenues from 2018 to 2020. 
You should present a dashboard that answers the questions sent by the investments sector.
1 - Is our hotel revenue growing by year?
2 - Should we increase our parking lot size?
3 - What trends can we see in the data? */

/* EXPLORING THE DATA 
We have three different tables for the 3 years (2018, 2019 and 2020), let's bring them all together in one table.
That means using SELECT and UNION to bring all three tables into one and answers the business questions. */
WITH hotelsRevenue AS (
	SELECT * FROM dbo.['2018$']
	UNION
	SELECT * FROM dbo.['2019$']
	UNION
	SELECT * FROM dbo.['2020$'])
/* We can also join the market_segment table, which shows the given discount for each professional, with the market_segment column from this new table:

QUESTION 1 - Is our hotel revenue growing by year?
Unfortunately, we don't have a revenue column. What we have is a Average Daily Rate (ADR) and the number of nights that
our guest stayed on weekdays and weekend. So a good ideia would be first summing the those two columns. That will return
the revenue for each row. After that, we will separate those revenues by year and sum them all.*/


SELECT arrival_date_year, hotel, ROUND(SUM((stays_in_week_nights + stays_in_weekend_nights) * adr),2) AS revenue 
FROM hotelsRevenue
GROUP BY arrival_date_year, hotel

/* The City hotel has a 1.7 milion revenue in 2018, 10.7 milion in 2019 and 8 milion in 2020. But we have to keep in mind
that 2020 data only reaches until August, so that year it's not over yet. For the Resort Hotel, the 2018 revenue was
3.12 milion, the 2019 revenue is 9.43 milion and we have 6.26 milion revenue in 2020. So, we can tell for sure that
revenue is growing. But we need more details, that will be explained in Power BI.*/

/* To make a dashboard on Power BI, we should first take also the information from the other two tables: dbo.market_segment and
dbo.meal_cost. For that, we will be joining those two tables into our hotelsRevenue table to make all the way into Power BI. */


SELECT * FROM hotelsRevenue
LEFT JOIN dbo.market_segment$
on hotelsRevenue.market_segment = market_segment$.market_segment
LEFT JOIN dbo.meal_cost$
on meal_cost$.meal = hotelsRevenue.meal


/* With Power BI, now we can use the first query (hotelsRevenue) and the last query (left join) during import. With the discount column, 
we need to consider that now in our revenue column. So we will use transform data to make a new column there, with the exact same lines 
as we did in the query, but adding discount:
(([stays_in_weekend_nights] + [stays_in_week_nights]) * [adr]) * ( 1 - [Discount])
 
1 - Is our hotel revenue growing by year?
Yes, we had a great increase starting from July 2018 and peaking on July 2019, but the start of COVID-19 pandemic hardly affected 
our reserves. We are experiencing several revenue decreases since July 2020.

2 - Should we increase our parking lot size?
If we consider only the increase from 2018 to 2019 and the good numbers until July 2020, we are tended to answer yes, because we had almost 
400% increase in parking request from 2018 to 2019. But since we are going through a decrease of reverses, which only tends to get worse at least for the next months because of COVID-19 pandemic. So, we recommend, at least until mid 2021 to not increase the parking lot size.

3 - What trends can we see in the data?
We can see many things troughout the data, so on:
- As already explained, we are experiencing a descrese of reserves, which causes a decrease of revenue;
- The City Hotel got more revenue than Resort Hotel, with more descounts by mean, 26,70% for City vs 24,48% for Resort;
- Portugal, Great Britain, France and Spain are the countries where most of our revenue come from. Germany and Ireland 
also had great performance.
*/
