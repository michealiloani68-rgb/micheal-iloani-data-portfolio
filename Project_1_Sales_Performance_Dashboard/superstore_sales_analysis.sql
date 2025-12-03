/*==========================================================
  Superstore Sales Analysis – Example Queries
  Author: Micheal Iloani
  Description:
    A collection of SQL queries used to explore the
    Superstore dataset and generate insights for
    the Power BI dashboard.
==========================================================*/

-----------------------------------------------------------
-- 0. QUICK CHECKS
-----------------------------------------------------------

-- See first 10 rows
SELECT TOP 10 *
FROM Orders;

-- Check basic row count
SELECT COUNT(*) AS TotalRows
FROM Orders;

-- Check date range
SELECT 
    MIN(OrderDate) AS FirstOrderDate,
    MAX(OrderDate) AS LastOrderDate
FROM Orders;


-----------------------------------------------------------
-- 1. CORE KPI QUERIES
-----------------------------------------------------------

-- 1.1 Total Sales, Profit, Quantity
SELECT
    SUM(Sales)    AS TotalSales,
    SUM(Profit)   AS TotalProfit,
    SUM(Quantity) AS TotalQuantity,
    SUM(Profit) / NULLIF(SUM(Sales), 0) AS ProfitMargin
FROM Orders;


-- 1.2 Sales and Profit by Region
SELECT
    Region,
    SUM(Sales)  AS TotalSales,
    SUM(Profit) AS TotalProfit,
    SUM(Profit) / NULLIF(SUM(Sales), 0) AS ProfitMargin
FROM Orders
GROUP BY Region
ORDER BY TotalSales DESC;


-- 1.3 Sales and Profit by Category
SELECT
    Category,
    SUM(Sales)  AS TotalSales,
    SUM(Profit) AS TotalProfit,
    SUM(Profit) / NULLIF(SUM(Sales), 0) AS ProfitMargin
FROM Orders
GROUP BY Category
ORDER BY TotalSales DESC;


-- 1.4 Top 10 Sub-Categories by Profit
SELECT
    SubCategory,
    SUM(Sales)  AS TotalSales,
    SUM(Profit) AS TotalProfit
FROM Orders
GROUP BY SubCategory
ORDER BY TotalProfit DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;


-----------------------------------------------------------
-- 2. CUSTOMER & SEGMENT ANALYSIS
-----------------------------------------------------------

-- 2.1 Top 20 Customers by Profit
SELECT TOP 20
    CustomerName,
    Segment,
    SUM(Sales)  AS TotalSales,
    SUM(Profit) AS TotalProfit
FROM Orders
GROUP BY CustomerName, Segment
ORDER BY TotalProfit DESC;


-- 2.2 Sales and Profit by Segment
SELECT
    Segment,
    COUNT(DISTINCT CustomerName) AS UniqueCustomers,
    SUM(Sales)  AS TotalSales,
    SUM(Profit) AS TotalProfit,
    SUM(Profit) / NULLIF(SUM(Sales), 0) AS ProfitMargin
FROM Orders
GROUP BY Segment
ORDER BY TotalSales DESC;


-----------------------------------------------------------
-- 3. TIME SERIES ANALYSIS
-----------------------------------------------------------

-- 3.1 Monthly Sales and Profit
-- (Useful for line charts in Power BI)
SELECT
    CAST(DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS DATE) AS MonthStart,
    SUM(Sales)  AS MonthlySales,
    SUM(Profit) AS MonthlyProfit
FROM Orders
GROUP BY DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
ORDER BY MonthStart;


-- 3.2 Yearly Sales and Profit
SELECT
    YEAR(OrderDate) AS OrderYear,
    SUM(Sales)      AS YearlySales,
    SUM(Profit)     AS YearlyProfit
FROM Orders
GROUP BY YEAR(OrderDate)
ORDER BY OrderYear;


-- 3.3 Year-on-Year (YoY) Sales Growth
-- (Basic version using a self-join on year)
WITH Yearly AS (
    SELECT
        YEAR(OrderDate) AS OrderYear,
        SUM(Sales)      AS YearlySales
    FROM Orders
    GROUP BY YEAR(OrderDate)
)
SELECT
    cur.OrderYear,
    cur.YearlySales,
    prev.YearlySales AS PreviousYearSales,
    (cur.YearlySales - prev.YearlySales)        AS SalesChange,
    (cur.YearlySales - prev.YearlySales)
        / NULLIF(prev.YearlySales, 0.0) * 100.0 AS YoY_Sales_Growth_Percent
FROM Yearly cur
LEFT JOIN Yearly prev
    ON cur.OrderYear = prev.OrderYear + 1
ORDER BY cur.OrderYear;


-----------------------------------------------------------
-- 4. DISCOUNT & PROFITABILITY
-----------------------------------------------------------

-- 4.1 Average Discount vs Profit by Sub-Category
SELECT
    SubCategory,
    AVG(Discount) AS AvgDiscount,
    SUM(Sales)    AS TotalSales,
    SUM(Profit)   AS TotalProfit,
    SUM(Profit) / NULLIF(SUM(Sales), 0) AS ProfitMargin
FROM Orders
GROUP BY SubCategory
ORDER BY AvgDiscount DESC;


-- 4.2 High Discount, Low Profit Products
-- (Helps identify problem areas)
SELECT
    SubCategory,
    SUM(Sales)    AS TotalSales,
    SUM(Profit)   AS TotalProfit,
    AVG(Discount) AS AvgDiscount
FROM Orders
GROUP BY SubCategory
HAVING AVG(Discount) > 0.2      -- more than 20% discount on average
   AND SUM(Profit) < 0          -- overall unprofitable
ORDER BY AvgDiscount DESC;


-----------------------------------------------------------
-- 5. GEOGRAPHY ANALYSIS
-----------------------------------------------------------

-- 5.1 Sales by State (or City)
SELECT
    State,
    SUM(Sales)  AS TotalSales,
    SUM(Profit) AS TotalProfit
FROM Orders
GROUP BY State
ORDER BY TotalSales DESC;


-- 5.2 Top 10 Cities by Sales
SELECT TOP 10
    City,
    State,
    SUM(Sales)  AS TotalSales,
    SUM(Profit) AS TotalProfit
FROM Orders
GROUP BY City, State
ORDER BY TotalSales DESC;


-----------------------------------------------------------
-- 6. ORDER-LEVEL METRICS
-----------------------------------------------------------

-- 6.1 Average Order Value (AOV)
SELECT
    SUM(Sales) * 1.0 / COUNT(DISTINCT OrderID) AS AverageOrderValue
FROM Orders;


-- 6.2 Orders with Negative Profit
SELECT
    OrderID,
    OrderDate,
    CustomerName,
    SubCategory,
    Sales,
    Profit
FROM Orders
WHERE Profit < 0
ORDER BY Profit ASC;
