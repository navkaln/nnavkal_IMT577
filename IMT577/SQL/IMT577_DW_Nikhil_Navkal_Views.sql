/*****************************************
Course: IMT 577
Instructor: Sean Pettersen
IT Module: 8
Date: 5/23/2022
Notes: Create views to answer course questions.

Steps:
    1. Build Fact_SRCSalesTarget
    2. Build Fact_SalesActual
    3. Build Fact_SRCSalesActual
*****************************************/


/** 

QUESTIONS FOR SEAN
How can I identify retail from wholesale sales channels?
I have 3 days left in my trial...

**/
USE SCHEMA IMT577_DW_Nikhil_Navkal.PUBLIC;

/** Create view for question 1:
1. Give an overall assessment of stores number 10 and 21’s sales.

How are they performing compared to target? Will they meet their 2014 target?
Should either store be closed? Why or why not?
What should be done in the next year to maximize store profits?

 **/
CREATE SECURE VIEW "Store Sales vs Targets"
(
   Date
   ,Year
   ,SaleAmount
   ,SaleQuantity
   ,SaleUnitPrice
   ,SaleExtendedCost
   ,SaleRetailProfit
   ,SalesTargetAmount
   ,StoreNumber
   ,StoreManager
   ,SourceStoreID
   ,PostalCode
   ,Gender
   ,Email
) AS
SELECT 
//top 100
//count(*)
DIM_DATE.Date
,DIM_DATE.Year
,FACT_SALESACTUAL.SaleAmount
,FACT_SALESACTUAL.SaleQuantity
,FACT_SALESACTUAL.SaleUnitPrice
,FACT_SALESACTUAL.SaleExtendedCost
,FACT_SALESACTUAL.SaleRetailProfit
,FACT_SRCSALESTARGET.SalesTargetAmount
,DIM_STORE.StoreNumber
,DIM_STORE.StoreManager
,DIM_STORE.SourceStoreID
,DIM_LOCATION.PostalCode
,DIM_CUSTOMER.Gender
,DIM_CUSTOMER.Email
FROM FACT_SALESACTUAL
INNER JOIN DIM_DATE ON DIM_DATE.Date_PKey = FACT_SALESACTUAL.DimSalesDateID
INNER JOIN FACT_SRCSALESTARGET ON FACT_SRCSALESTARGET.DimTargetDateID = FACT_SALESACTUAL.DimSalesDateID
                               AND FACT_SRCSALESTARGET.DimStoreID = FACT_SALESACTUAL.DimStoreID
INNER JOIN DIM_STORE ON DIM_STORE.DimStoreID = FACT_SALESACTUAL.DimStoreID
INNER JOIN DIM_LOCATION ON DIM_LOCATION.DimLocationID = FACT_SALESACTUAL.DimLocationID
INNER JOIN DIM_CUSTOMER ON DIM_CUSTOMER.DimCustomerID = FACT_SALESACTUAL.DimCustomerID
WHERE FACT_SALESACTUAL.DimStoreID > -1
    AND DIM_STORE.StoreNumber IN (10, 21)



/** Create view for question 2:
2. Recommend 2013 bonus amounts for each store if the total bonus pool is $2,000,000 using a
comparison of 2013 actual sales vs. 2013 sales targets as the basis for the recommendation.
**/

--sales goal views
CREATE SECURE VIEW "2013 Sales Goal Hits Raw"
(
  DimSalesDateID
  ,StoreNumber
  ,SaleAmount
  ,SalesTargetAmount
  ,PercentHit
) AS
SELECT 
    FACT_SALESACTUAL.DimSalesDateID
    ,DIM_STORE.StoreNumber
    ,SUM(FACT_SALESACTUAL.SaleAmount) AS SaleAmount
    ,StoreDailyTargets.SalesTargetAmount
    ,100 * (SUM(FACT_SALESACTUAL.SaleAmount) / StoreDailyTargets.SalesTargetAmount) AS PercentHit
FROM 
    FACT_SALESACTUAL
    ,DIM_STORE
    ,(SELECT
          FACT_SRCSALESTARGET.DimTargetDateID
          ,FACT_SRCSALESTARGET.SalesTargetAmount
          ,DIM_STORE.StoreNumber
      FROM FACT_SRCSALESTARGET, DIM_STORE
      WHERE DIM_STORE.DimStoreID = FACT_SRCSALESTARGET.DimStoreID
          AND DIM_STORE.DimStoreID > -1
          AND LEFT(FACT_SRCSALESTARGET.DimTargetDateID, 4) = '2013'
     ) StoreDailyTargets
WHERE
    DIM_STORE.DimStoreID = FACT_SALESACTUAL.DimStoreID
    AND DIM_STORE.DimStoreID > -1
    AND LEFT(FACT_SALESACTUAL.DimSalesDateID, 4) = '2013'
    AND StoreDailyTargets.StoreNumber = DIM_STORE.StoreNumber
    AND StoreDailyTargets.DimTargetDateID = FACT_SALESACTUAL.DimSalesDateID
GROUP BY 
    FACT_SALESACTUAL.DimSalesDateID
    ,DIM_STORE.StoreNumber
    ,StoreDailyTargets.SalesTargetAmount
    
    
CREATE SECURE VIEW "2013 Sales Goal Hits Aggregate"    
(
    StoreNumber
    ,SaleAmount
    ,SalesTargetAmount
    ,PercentHit
) AS
SELECT 
    DIM_STORE.StoreNumber
    ,SUM(FACT_SALESACTUAL.SaleAmount) AS SaleAmount
    ,(365 * StoreDailyTargets.SalesTargetAmount) AS SalesTargetAmount
    ,100 * (SUM(FACT_SALESACTUAL.SaleAmount) / (365 * StoreDailyTargets.SalesTargetAmount)) AS PercentHit
FROM 
    FACT_SALESACTUAL
    ,DIM_STORE
    ,(SELECT
          FACT_SRCSALESTARGET.DimTargetDateID
          ,FACT_SRCSALESTARGET.SalesTargetAmount
          ,DIM_STORE.StoreNumber
      FROM FACT_SRCSALESTARGET, DIM_STORE
      WHERE DIM_STORE.DimStoreID = FACT_SRCSALESTARGET.DimStoreID
          AND DIM_STORE.DimStoreID > -1
          AND LEFT(FACT_SRCSALESTARGET.DimTargetDateID, 4) = '2013'
     ) StoreDailyTargets
WHERE
    DIM_STORE.DimStoreID = FACT_SALESACTUAL.DimStoreID
    AND DIM_STORE.DimStoreID > -1
    AND LEFT(FACT_SALESACTUAL.DimSalesDateID, 4) = '2013'
    AND StoreDailyTargets.StoreNumber = DIM_STORE.StoreNumber
    AND StoreDailyTargets.DimTargetDateID = FACT_SALESACTUAL.DimSalesDateID
GROUP BY 
    DIM_STORE.StoreNumber
    ,StoreDailyTargets.SalesTargetAmount


--StoreDailyTargets
SELECT
    FACT_SRCSALESTARGET.DimTargetDateID
    ,FACT_SRCSALESTARGET.SalesTargetAmount
    ,DIM_STORE.StoreNumber
FROM FACT_SRCSALESTARGET, DIM_STORE
WHERE DIM_STORE.DimStoreID = FACT_SRCSALESTARGET.DimStoreID
    AND DIM_STORE.DimStoreID > -1
    AND LEFT(FACT_SRCSALESTARGET.DimTargetDateID, 4) = '2013'


 
/** Create view for question 3:
3.  Assess product sales by day of the week at stores 10 and 21. What can we learn about sales trends?
**/
 
--product targets by day aggregated
CREATE SECURE VIEW "Product Sales by Day of Week Aggregated"
(
ProductName
,StoreNumber
,ProductType
,ProductCategory
,ProductTargetSalesQuantity
,DaysRecorded
,Day_Name
,SalesAmount
,PercentOfTarget
) AS
SELECT
  DIM_PRODUCT.ProductName
  ,DIM_STORE.StoreNumber
  ,DIM_PRODUCT.ProductType
  ,DIM_PRODUCT.ProductCategory
  ,sum(FACT_PRODUCTSALESTARGET.ProductTargetSalesQuantity) AS ProductTargetSalesQuantity
  ,OperationalDaysRecorded.DaysRecorded
  ,OperationalDaysRecorded.Day_Name
  ,sum(ProductDateStoreSales.SalesAmount) AS SalesAmount
  ,sum(ProductDateStoreSales.SalesAmount) / sum(FACT_PRODUCTSALESTARGET.ProductTargetSalesQuantity) AS PercentOfTarget
FROM 
  DIM_PRODUCT
  ,FACT_PRODUCTSALESTARGET
  ,(SELECT DIM_DATE.Date_PKey, OperationalDays.*
    FROM DIM_DATE,
        (SELECT COUNT(*) AS DaysRecorded, Year ,Day_Name
         FROM DIM_DATE
              ,(SELECT DISTINCT DimSalesDateID FROM FACT_SALESACTUAL) a
         WHERE a.DimSalesDateID = DIM_DATE.Date_PKey 
         GROUP BY Day_Name, Year) OperationalDays
    WHERE DIM_DATE.Year = OperationalDays.Year 
        AND DIM_DATE.Day_Name = OperationalDays.Day_Name) OperationalDaysRecorded
   ,(SELECT 
        DIM_PRODUCT.ProductName
        ,DIM_DATE.Date_PKey
        ,FACT_SALESACTUAL.DimStoreID
        ,SUM(FACT_SALESACTUAL.SaleAmount) AS SalesAmount
    FROM FACT_SALESACTUAL, DIM_PRODUCT, DIM_DATE
    WHERE FACT_SALESACTUAL.DimProductID = DIM_PRODUCT.DimProductID
        AND DIM_DATE.Date_PKey = FACT_SALESACTUAL.DimSalesDateID
        AND FACT_SALESACTUAL.DimStoreID > 0
    GROUP BY DIM_DATE.Date_PKey, DIM_PRODUCT.ProductName, FACT_SALESACTUAL.DimStoreID
    ) ProductDateStoreSales
    ,DIM_STORE
WHERE DIM_PRODUCT.DimProductID = FACT_PRODUCTSALESTARGET.DimProductID
   AND OperationalDaysRecorded.Date_PKey = FACT_PRODUCTSALESTARGET.DimTargetDateID
   AND ProductDateStoreSales.Date_PKey = FACT_PRODUCTSALESTARGET.DimTargetDateID
   AND ProductDateStoreSales.ProductName = DIM_PRODUCT.ProductName
   AND DIM_STORE.DimStoreID = ProductDateStoreSales.DimStoreID
   AND DIM_STORE.StoreNumber in (10,21)
GROUP BY 
    OperationalDaysRecorded.Day_Name
    ,OperationalDaysRecorded.DaysRecorded
    ,DIM_STORE.StoreNumber
    ,DIM_PRODUCT.ProductName
    ,DIM_PRODUCT.ProductType
    ,DIM_PRODUCT.ProductCategory


CREATE SECURE VIEW "Product Sales by Day of Week Raw"
(
ProductName
,StoreNumber
,ProductType
,ProductCategory
,DimTargetDateID
,ProductTargetSalesQuantity
,DaysRecorded
,Day_Name
,SalesAmount
,PercentOfTarget
) AS
SELECT
  DIM_PRODUCT.ProductName
  ,DIM_STORE.StoreNumber
  ,DIM_PRODUCT.ProductType
  ,DIM_PRODUCT.ProductCategory
  ,FACT_PRODUCTSALESTARGET.DimTargetDateID
  ,FACT_PRODUCTSALESTARGET.ProductTargetSalesQuantity
  ,OperationalDaysRecorded.DaysRecorded
  ,OperationalDaysRecorded.Day_Name
  ,ProductDateStoreSales.SalesAmount
  ,ProductDateStoreSales.SalesAmount / FACT_PRODUCTSALESTARGET.ProductTargetSalesQuantity AS PercentOfTarget
FROM 
  DIM_PRODUCT
  ,FACT_PRODUCTSALESTARGET
  ,(SELECT DIM_DATE.Date_PKey, OperationalDays.*
    FROM DIM_DATE,
        (SELECT COUNT(*) AS DaysRecorded, Year ,Day_Name
         FROM DIM_DATE
              ,(SELECT DISTINCT DimSalesDateID FROM FACT_SALESACTUAL) a
         WHERE a.DimSalesDateID = DIM_DATE.Date_PKey 
         GROUP BY Day_Name, Year) OperationalDays
    WHERE DIM_DATE.Year = OperationalDays.Year 
        AND DIM_DATE.Day_Name = OperationalDays.Day_Name) OperationalDaysRecorded
   ,(SELECT 
        DIM_PRODUCT.ProductName
        ,DIM_DATE.Date_PKey
        ,FACT_SALESACTUAL.DimStoreID
        ,SUM(FACT_SALESACTUAL.SaleAmount) AS SalesAmount
    FROM FACT_SALESACTUAL, DIM_PRODUCT, DIM_DATE
    WHERE FACT_SALESACTUAL.DimProductID = DIM_PRODUCT.DimProductID
        AND DIM_DATE.Date_PKey = FACT_SALESACTUAL.DimSalesDateID
        AND FACT_SALESACTUAL.DimStoreID > 0
    GROUP BY DIM_DATE.Date_PKey, DIM_PRODUCT.ProductName, FACT_SALESACTUAL.DimStoreID
    ) ProductDateStoreSales
    ,DIM_STORE
WHERE DIM_PRODUCT.DimProductID = FACT_PRODUCTSALESTARGET.DimProductID
   AND OperationalDaysRecorded.Date_PKey = FACT_PRODUCTSALESTARGET.DimTargetDateID
   AND ProductDateStoreSales.Date_PKey = FACT_PRODUCTSALESTARGET.DimTargetDateID
   AND ProductDateStoreSales.ProductName = DIM_PRODUCT.ProductName
   AND DIM_STORE.DimStoreID = ProductDateStoreSales.DimStoreID
   AND DIM_STORE.StoreNumber in (10,21)


--ProductDateStoreSales
SELECT 
    DIM_PRODUCT.ProductName
    ,DIM_DATE.Date_PKey
    ,FACT_SALESACTUAL.DimStoreID
    ,SUM(FACT_SALESACTUAL.SaleAmount) AS SalesAmount
FROM FACT_SALESACTUAL, DIM_PRODUCT, DIM_DATE
WHERE FACT_SALESACTUAL.DimProductID = DIM_PRODUCT.DimProductID
    AND DIM_DATE.Date_PKey = FACT_SALESACTUAL.DimSalesDateID
    AND FACT_SALESACTUAL.DimStoreID > 0
GROUP BY DIM_DATE.Date_PKey, DIM_PRODUCT.ProductName, FACT_SALESACTUAL.DimStoreID


-- Operational Days (Days where Sales were recorded)
SELECT DIM_DATE.Date_PKey, OperationalDays.*
    FROM DIM_DATE,
        (SELECT COUNT(*) AS DaysRecorded, Year ,Day_Name
         FROM DIM_DATE
              ,(SELECT DISTINCT DimSalesDateID FROM FACT_SALESACTUAL) a
         WHERE a.DimSalesDateID = DIM_DATE.Date_PKey 
         GROUP BY Day_Name, Year) OperationalDays
    WHERE DIM_DATE.Year = OperationalDays.Year 
        AND DIM_DATE.Day_Name = OperationalDays.Day_Name) OperationalDaysRecorded



/** Create view for question 4:
4. Should any new stores be opened? Include all stores in your analysis if necessary. If so, where? Why or why not?
**/
 
CREATE SECURE VIEW "New Store Location"
(
  StoreNumber
  ,PostalCode
  ,SaleAmount
  ,SaleExtendedCost
  ,SaleRetailProfit
  ,SaleWholesaleProfit
) AS
SELECT
    StoreLocations.StoreNumber
    ,StoreLocations.PostalCode
    ,SUM(FACT_SALESACTUAL.SaleAmount) AS SaleAmount
    ,SUM(FACT_SALESACTUAL.SaleExtendedCost) AS SaleExtendedCost
    ,SUM(FACT_SALESACTUAL.SaleRetailProfit) AS SaleRetailProfit
    ,SUM(FACT_SALESACTUAL.SaleWholesaleProfit) AS SaleWholesaleProfit
FROM 
    FACT_SALESACTUAL
    ,(SELECT * 
    FROM 
        DIM_LOCATION
        ,DIM_STORE
    WHERE DIM_STORE.SourceStoreID = DIM_LOCATION.DimLocationID
        AND DIM_STORE.DimStoreID > -1
    ) StoreLocations
WHERE StoreLocations.DimStoreID = FACT_SALESACTUAL.DimStoreID
GROUP BY
    StoreLocations.StoreNumber
    ,StoreLocations.PostalCode


--StoreLocations
SELECT * 
FROM 
    DIM_LOCATION
    ,DIM_STORE
WHERE DIM_STORE.SourceStoreID = DIM_LOCATION.DimLocationID
AND DIM_STORE.DimStoreID > -1



/** Create passthrough views **/

CREATE SECURE VIEW "Sales Actual Passthrough"
( 
DIMPRODUCTID
,DIMSTOREID
,DIMRESELLERID
,DIMCUSTOMERID
,DIMCHANNELID
,DIMSALESDATEID
,DIMLOCATIONID
,SOURCESSALESHEADERID
,SOURCESALESDETAILID
,SALEAMOUNT
,SALEQUANTITY
,SALEUNITPRICE
,SALEEXTENDEDCOST
,SALERETAILPROFIT
,SALEWHOLESALEPROFIT
) AS
SELECT
FACT_SALESACTUAL.DIMPRODUCTID
,FACT_SALESACTUAL.DIMSTOREID
,FACT_SALESACTUAL.DIMRESELLERID
,FACT_SALESACTUAL.DIMCUSTOMERID
,FACT_SALESACTUAL.DIMCHANNELID
,FACT_SALESACTUAL.DIMSALESDATEID
,FACT_SALESACTUAL.DIMLOCATIONID
,FACT_SALESACTUAL.SOURCESSALESHEADERID
,FACT_SALESACTUAL.SOURCESALESDETAILID
,FACT_SALESACTUAL.SALEAMOUNT
,FACT_SALESACTUAL.SALEQUANTITY
,FACT_SALESACTUAL.SALEUNITPRICE
,FACT_SALESACTUAL.SALEEXTENDEDCOST
,FACT_SALESACTUAL.SALERETAILPROFIT
,FACT_SALESACTUAL.SALEWHOLESALEPROFIT
FROM FACT_SALESACTUAL


CREATE SECURE VIEW "Product Sales Target Passthrough"
( 
DIMPRODUCTID
,DIMTARGETDATEID
,PRODUCTTARGETSALESQUANTITY
) AS
SELECT
DIMPRODUCTID
,DIMTARGETDATEID
,PRODUCTTARGETSALESQUANTITY
FROM FACT_PRODUCTSALESTARGET


CREATE SECURE VIEW "Sales Target Passthrough"
( 
DIMSTOREID
,DIMRESELLERID
,DIMCHANNELID
,DIMTARGETDATEID
,SALESTARGETAMOUNT
) AS
SELECT
DIMSTOREID
,DIMRESELLERID
,DIMCHANNELID
,DIMTARGETDATEID
,SALESTARGETAMOUNT
FROM FACT_SRCSALESTARGET
