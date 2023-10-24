--Inspecting the Data 
select * from [dbo].[sales_data]

--Analysis
--Grouping sales by productline

Select PRODUCTLINE, SUM(SALES) Revenue 
from [dbo].[sales_data]
group by PRODUCTLINE
order by 2 desc

--Grouping sales  by Year
Select YEAR_ID, SUM(SALES) Revenue_PA 
from [dbo].[sales_data]
group by YEAR_ID
order by 2 desc

--Grouping sales by Dealsize
Select DEALSIZE, SUM(SALES) Revenue_DealSize
from [dbo].[sales_data]
group by DEALSIZE
order by 2 desc

--Checking which month has most sales in a specific year. How much was earned that month
Select MONTH_ID, SUM(SALES) Revenue ,COUNT(ORDERNUMBER) Frequency
From [dbo].[sales_data]
where YEAR_ID = 2003 --Change Year to see the rest
group by MONTH_ID
order by 2 desc

--November is the best month, inspecting what product line sales the most
Select MONTH_ID, PRODUCTLINE, SUM(SALES) Revenue ,COUNT(ORDERNUMBER) Frequency
From [dbo].[sales_data]
where YEAR_ID = 2003 and MONTH_ID = 11 --Change Year to see the rest
group by MONTH_ID,PRODUCTLINE
order by 3 desc

--RFM Analysis - to determine the best customers 
DROP TABLE IF exists #rfm
;With RFM as 
(
	Select
		CUSTOMERNAME,
		SUM(SALES) MoneyValue,
		AVG(SALES) AveragemonetaryValue,
		COUNT(ORDERNUMBER) Frequency,
		MAX(ORDERDATE) Last_Order_date,
		(select MAX(ORDERDATE) from[dbo].[sales_data]) Max_order_date,
		DATEDIFF(DD,MAX(ORDERDATE),(select MAX(ORDERDATE) from[dbo].[sales_data])) Recency
	From [dbo].[sales_data]
	group by CUSTOMERNAME
),
RFM_calc as 
(
	select r.*,
		NTILE(4) OVER(order by Recency desc) RFM_Recency,
		NTILE(4) OVER(order by Frequency) RFM_Frequency,
		NTILE(4) OVER(order by MoneyValue) RFM_Monetary
	from RFM r
)
select 
	c.*,RFM_Recency+RFM_Frequency+RFM_Monetary as RFM_cell,
	CAST(RFM_Recency as varchar) + CAST(RFM_Frequency as varchar) + CAST(RFM_Monetary as varchar) RFM_Cell_String
into #rfm
from RFM_calc c

select CUSTOMERNAME,RFM_Recency,RFM_Frequency,RFM_Monetary,
	CASE
		when RFM_Cell_String in (111, 112,121,122,123,132, 211,212,114,141) then 'lost_cutomers' --lost customers
		when RFM_Cell_String in (133,134,143,244,334,343,344,144) then 'Slipping away, cannot lose' --Big spenders who havent purchased recently
		when RFM_Cell_String in (311,411,331) then 'new customers' 
		when RFM_Cell_String in (222,223,233, 322) then 'potential churners' 
		when RFM_Cell_String in (323,333,321,422,332,432) then 'active' --customers who buy often & recently, but at low price points
		when RFM_Cell_String in (433,434,443, 444) then 'loyal'
	end rfm_segment
from #rfm

--What products are most often sold together
--select * from [dbo].[sales_data] where ORDERNUMBER = 10370
select distinct ORDERNUMBER,STUFF(

(select ',' +PRODUCTCODE
from[dbo].[sales_data] p
where ORDERNUMBER in
	(
		Select ORDERNUMBER
		from(
			Select ORDERNUMBER, COUNT(*) rn
			from [dbo].[sales_data]
			where STATUS = 'Shipped'
			group by ORDERNUMBER
		)m
		where rn = 3
	)
	and 
	p.ORDERNUMBER = s.ORDERNUMBER
	for xml path('')),
	1, 1, '') productCodes
from [dbo].[sales_data] s
order by 2 desc