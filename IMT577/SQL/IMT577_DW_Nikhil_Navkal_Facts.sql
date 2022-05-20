/*****************************************
Course: IMT 577
Instructor: Sean Pettersen
IT Session: 8
Date: 5/18/2022
Notes: Create dimension tables & load.

Steps:
    
    1. Build Fact_SRCSalesTarget
    2. Build Fact_SalesActual
    3. Build Fact_SRCSalesActual
*****************************************/


/** 

QUESTIONS FOR SEAN

Why do we use surrogate keys for our dimension primary keys? Does that come with risk?
Should we anticipate one to many relationship between SalesHeader and SalesDetail?

**/
USE SCHEMA IMT577_DW_Nikhil_Navkal.PUBLIC;

SELECT * FROM FACT_SRCSALESTARGET;
SELECT * FROM FACT_PRODUCTSALESTARGET;
SELECT * FROM FACT_SALESACTUAL;

DROP TABLE IF EXISTS FACT_SRCSALESTARGET;
DROP TABLE IF EXISTS FACT_PRODUCTSALESTARGET;
DROP TABLE IF EXISTS FACT_SALESACTUAL;


-- Had to fix naming convention for dim_channel key
-- ALTER TABLE Dim_Channel RENAME COLUMN Dim_ChannelID TO DimChannelID 
-- ALTER TABLE Dim_Product RENAME COLUMN Dim_ProductID TO DimProductID



/** CREATE FACT_SRCSALESTARGET FACT TABLE **/
-- create table
CREATE OR REPLACE TABLE FACT_SRCSALESTARGET
(
    DimStoreID INT CONSTRAINT FK_DimStoreID FOREIGN KEY REFERENCES Dim_Store(DimStoreID),
    DimResellerID INT CONSTRAINT FK_DimResellerID FOREIGN KEY REFERENCES Dim_Reseller(DimResellerID),
    DimChannelID INT CONSTRAINT FK_DimChannelID FOREIGN KEY REFERENCES Dim_Channel(DimChannelID),
    DimTargetDateID NUMBER(9) CONSTRAINT FK_DimTargetDateID FOREIGN KEY REFERENCES DIM_DATE(DATE_PKEY),
    SalesTargetAmount FLOAT
)

-- insert values (8030 rows added)
INSERT INTO FACT_SRCSALESTARGET
(
    DimStoreID,
    DimResellerID,
    DimChannelID,
    DimTargetDateID,
    SalesTargetAmount
)
SELECT 
    NVL(DIM_STORE.DIMSTOREID, -1) AS DIMSTOREID,
    NVL(DIM_RESELLER.DIMRESELLERID, -1) AS DIMRESELLERID,
    NVL(DIM_CHANNEL.DIMCHANNELID, -1) AS DIMCHANNELID,
    DIM_DATE.DATE_PKEY,
    STAGE_TARGETDATACHANNEL.TARGETSALESAMOUNT / 365
FROM
    STAGE_TARGETDATACHANNEL
    LEFT JOIN DIM_STORE ON
    (CASE
        WHEN RLIKE(STAGE_TARGETDATACHANNEL.TARGETNAME, '.*\\d+$') 
            THEN REGEXP_SUBSTR(STAGE_TARGETDATACHANNEL.TARGETNAME, '\\d+')
            ELSE STAGE_TARGETDATACHANNEL.TARGETNAME
    END) = TO_VARCHAR(DIM_STORE.STORENUMBER)
    LEFT JOIN DIM_RESELLER ON STAGE_TARGETDATACHANNEL.TARGETNAME = DIM_RESELLER.RESELLERNAME
    LEFT JOIN DIM_CHANNEL ON STAGE_TARGETDATACHANNEL.CHANNELNAME = DIM_CHANNEL.CHANNELNAME
    INNER JOIN DIM_DATE ON DIM_DATE.YEAR = STAGE_TARGETDATACHANNEL.YEAR
    ORDER BY DIM_DATE.DATE_PKEY

select * FROM FACT_SRCSALESTARGET
-- 8030



/** CREATE FACT_PRODUCTSALESTARGET FACT TABLE **/
-- create table
CREATE OR REPLACE TABLE FACT_PRODUCTSALESTARGET
(
    DimProductID INT CONSTRAINT FK_DimProductID FOREIGN KEY REFERENCES Dim_Product(DimProductID),
    DimTargetDateID NUMBER(9) CONSTRAINT FK_DimTargetDateID FOREIGN KEY REFERENCES DIM_DATE(DATE_PKEY),
    ProductTargetSalesQuantity FLOAT
)

-- insert values
INSERT INTO FACT_PRODUCTSALESTARGET
(
    DimProductID,
    DimTargetDateID,
    ProductTargetSalesQuantity
)
SELECT 
    DIM_PRODUCT.DIMPRODUCTID,
    DIM_DATE.DATE_PKEY,
    STAGE_TARGETDATAPRODUCT.SALESQUANTITYTARGET / 365
FROM DIM_PRODUCT
    INNER JOIN STAGE_TARGETDATAPRODUCT ON DIM_PRODUCT.SOURCEPRODUCTID = STAGE_TARGETDATAPRODUCT.PRODUCTID
    INNER JOIN DIM_DATE ON DIM_DATE.YEAR = STAGE_TARGETDATAPRODUCT.YEAR
    ORDER BY DIM_DATE.DATE_PKEY


SELECT * FROM FACT_PRODUCTSALESTARGET
-- 17520 rows



/** CREATE FACT_SALESACTUAL FACT TABLE **/
CREATE OR REPLACE TABLE FACT_SALESACTUAL
(
    DimProductID INT CONSTRAINT FK_DimProductID FOREIGN KEY REFERENCES Dim_Product(DimProductID),
    DimStoreID INT CONSTRAINT FK_DimStoreID FOREIGN KEY REFERENCES Dim_Store(DimStoreID),
    DimResellerID INT CONSTRAINT FK_DimResellerID FOREIGN KEY REFERENCES Dim_Reseller(DimResellerID),
    DimCustomerID INT CONSTRAINT FK_DimCustomerID FOREIGN KEY REFERENCES Dim_Customer(DimCustomerID),
    DimChannelID INT CONSTRAINT FK_DimChannelID FOREIGN KEY REFERENCES Dim_Channel(DimChannelID),
    DimSalesDateID NUMBER(9) CONSTRAINT FK_DimSalesDateID FOREIGN KEY REFERENCES DIM_DATE(DATE_PKEY),
    DimLocationID INT CONSTRAINT FK_DimLocationID FOREIGN KEY REFERENCES Dim_Location(DimLocationID),
    SourcesSalesHeaderID INT,
    SourceSalesDetailID INT,
    SaleAmount INT,
    SaleQuantity INT,
    SaleUnitPrice FLOAT,
    SaleExtendedCost FLOAT,
    SaleRetailProfit FLOAT,
    SaleWholesaleProfit FLOAT
)

-- insert values (187320 rows)
INSERT INTO FACT_SALESACTUAL
(
    DimProductID
    ,DimStoreID
    ,DimResellerID
    ,DimCustomerID
    ,DimChannelID
    ,DimSalesDateID
    ,DimLocationID
    ,SourcesSalesHeaderID
    ,SourceSalesDetailID
    ,SaleAmount
    ,SaleQuantity
    ,SaleUnitPrice
    ,SaleExtendedCost
    ,SaleRetailProfit
    ,SaleWholesaleProfit
)
SELECT 
    DIM_PRODUCT.DIMPRODUCTID
    ,NVL(DIM_STORE.DIMSTOREID, -1) AS DIMSTOREID
    ,NVL(DIM_RESELLER.DIMRESELLERID, -1) AS DIMRESELLERID
    ,NVL(DIM_CUSTOMER.DIMCUSTOMERID, -1) AS DIMCUSTOMERID
    ,NVL(DIM_CHANNEL.DIMCHANNELID, -1) AS DIMCHANNELID
    ,NVL(DIM_LOCATION.DIMLOCATIONID, -1) AS DIMLOCATIONID
    ,DIM_DATE.DATE_PKEY AS DimSalesDateID
    ,STAGE_SALESDETAIL.SALESDETAILID AS SOURCESALESDETAILID
    ,STAGE_SALESHEADERNEW.SALESHEADERID AS SOURCESALESHEADERID
    ,STAGE_SALESDETAIL.SALESAMOUNT AS SALEAMOUNT
    ,STAGE_SALESDETAIL.SALESQUANTITY AS SALEQUANTITY
    ,SALESAMOUNT / SALESQUANTITY AS SALEUNITPRICE
    ,DIM_PRODUCT.PRODUCTCOST * STAGE_SALESDETAIL.SALESQUANTITY AS SALEEXTENDEDCOST
    ,DIM_PRODUCT.PRODUCTRETAILPROFIT * STAGE_SALESDETAIL.SALESQUANTITY AS SALERETAILPROFIT
    ,DIM_PRODUCT.PRODUCTWHOLESALEUNITPROFIT * STAGE_SALESDETAIL.SALESQUANTITY AS SALEWHOLESALEPROFIT
FROM 
    STAGE_SALESHEADERNEW
    INNER JOIN STAGE_SALESDETAIL ON STAGE_SALESHEADERNEW.SALESHEADERID = STAGE_SALESDETAIL.SALESHEADERID
    INNER JOIN DIM_PRODUCT ON DIM_PRODUCT.SOURCEPRODUCTID = STAGE_SALESDETAIL.PRODUCTID
    LEFT JOIN DIM_STORE ON STAGE_SALESHEADERNEW.STOREID = DIM_STORE.DIMSTOREID
    LEFT JOIN STAGE_RESELLER ON STAGE_SALESHEADERNEW.RESELLERID = STAGE_RESELLER.RESELLERID
    LEFT JOIN DIM_RESELLER ON STAGE_RESELLER.EMAILADDRESS = DIM_RESELLER.EMAIL
    LEFT JOIN STAGE_CUSTOMER ON STAGE_SALESHEADERNEW.CUSTOMERID = STAGE_CUSTOMER.CUSTOMERID
    LEFT JOIN DIM_CUSTOMER ON STAGE_CUSTOMER.EMAILADDRESS = DIM_CUSTOMER.EMAIL
    LEFT JOIN DIM_CHANNEL ON STAGE_SALESHEADERNEW.CHANNELID = DIM_CHANNEL.DIMCHANNELID
    LEFT JOIN DIM_DATE ON ADD_MONTHS(DATE(STAGE_SALESHEADERNEW.DATE), 24000) = DIM_DATE.DATE
    LEFT JOIN DIM_LOCATION ON
        (CASE
            WHEN STAGE_SALESHEADERNEW.STOREID = 1 THEN 1
            WHEN STAGE_SALESHEADERNEW.STOREID = 2 THEN 2
            WHEN STAGE_SALESHEADERNEW.STOREID = 3 THEN 3
            WHEN STAGE_SALESHEADERNEW.STOREID = 4 THEN 4
            WHEN STAGE_SALESHEADERNEW.STOREID = 5 THEN 5
            WHEN STAGE_SALESHEADERNEW.STOREID = 6 THEN 6
            WHEN STAGE_SALESHEADERNEW.RESELLERID = 'd56ef891-cbfa-4659-a44a-169aafb00587' THEN 7
            WHEN STAGE_SALESHEADERNEW.RESELLERID = '5be7aa4a-70b8-4515-88ba-b78395ff9710' THEN 8
            WHEN STAGE_SALESHEADERNEW.RESELLERID = '10418299-2934-4ca3-b368-d0dfcde58a51' THEN 9
            WHEN STAGE_SALESHEADERNEW.RESELLERID = '9c9706cb-9102-43c4-9e5a-dd38502a1284' THEN 10
            ELSE -1
        END
        ) = DIM_LOCATION.SOURCELOCATIONID

select * from FACT_SALESACTUAL;
--187320 rows

-- select add_months(date('1/1/13'), 24000)

-- -- for more elegant location join
-- SELECT * FROM dim_location, dim_reseller, stage_reseller
-- WHERE dim_location.sourcelocationid = dim_reseller.sourceresellerid
-- and dim_reseller.email = stage_reseller.emailaddress;

