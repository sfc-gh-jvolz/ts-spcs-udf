---------------------
----- 1 - SETUP ----- 
---------------------

// Create Database, Warehouse, and Image spec stage
USE ROLE CONTAINER_USER_ROLE;
CREATE OR REPLACE DATABASE CONTAINER_HOL_DB;

CREATE OR REPLACE WAREHOUSE CONTAINER_HOL_WH
  WAREHOUSE_SIZE = XSMALL
  AUTO_SUSPEND = 120
  AUTO_RESUME = TRUE;
  
CREATE STAGE IF NOT EXISTS specs
ENCRYPTION = (TYPE='SNOWFLAKE_SSE');

CREATE STAGE IF NOT EXISTS volumes
ENCRYPTION = (TYPE='SNOWFLAKE_SSE')
DIRECTORY = (ENABLE = TRUE);

CREATE COMPUTE POOL IF NOT EXISTS CONTAINER_HOL_POOL
MIN_NODES = 1
MAX_NODES = 1
INSTANCE_FAMILY = CPU_X64_XS;

CREATE IMAGE REPOSITORY CONTAINER_HOL_DB.PUBLIC.IMAGE_REPO;

SHOW IMAGE REPOSITORIES IN SCHEMA CONTAINER_HOL_DB.PUBLIC;
--get image repo url for local docker work 

-- do local docker workflow here 

-- after running docker push 
SHOW IMAGES IN IMAGE REPOSITORY CONTAINER_HOL_DB.PUBLIC.IMAGE_REPO;

--upload prophet-app.yaml to your @specs stage

-- after uploading check spec
ls @CONTAINER_HOL_DB.PUBLIC.SPECS;

------------------------------
----- 2 - CREATE SERVICE ----- 
------------------------------

create service CONTAINER_HOL_DB.PUBLIC.PROPHET_APP
    in compute pool CONTAINER_HOL_POOL
    from @SPECS
    specification_file='prophet-app.yaml'
    external_access_integrations = (ALLOW_ALL_EAI);

show services;

--describe service PROPHET_APP;

--CALL SYSTEM$GET_SERVICE_STATUS('CONTAINER_HOL_DB.PUBLIC.PROPHET_APP');

--CALL SYSTEM$GET_SERVICE_LOGS('CONTAINER_HOL_DB.PUBLIC.PROPHET_APP', '0', 'prophet-app');

-------------------------------------
----- 3 - CREATE SAMPLE DATA  ------- 
-------------------------------------

CREATE OR REPLACE TABLE CONTAINER_HOL_DB.PUBLIC.WEATHER (
    DATE DATE,
    TEMP NUMBER
);

INSERT INTO CONTAINER_HOL_DB.PUBLIC.WEATHER  (DATE, TEMP) 
    VALUES 
        ('2023-01-01', 15),
        ('2023-01-02', 20),
        ('2023-01-03', 17),
        ('2023-01-04', 19),
        ('2023-01-05', 13),
        ('2023-01-06', 11),
        ('2023-01-07', 21),
        ('2023-01-08', 16),
        ('2023-01-09', 18),
        ('2023-01-10', 12),
        ('2023-01-11', 15),
        ('2023-01-12', 20),
        ('2023-01-13', 17),
        ('2023-01-14', 19),
        ('2023-01-15', 13),
        ('2023-01-16', 11),
        ('2023-01-17', 21),
        ('2023-01-18', 16),
        ('2023-01-19', 18),
        ('2023-01-20', 12),
        ('2023-01-21', 15),
        ('2023-01-22', 20),
        ('2023-01-23', 17),
        ('2023-01-24', 19),
        ('2023-01-25', 13),
        ('2023-01-26', 11),
        ('2023-01-27', 21),
        ('2023-01-28', 16),
        ('2023-01-29', 18),
        ('2023-01-30', 12)
    ;


--validate 
select * from weather;

-------------------------------------
----- 4 - CREATE UDF          ------- 
-------------------------------------

CREATE OR REPLACE FUNCTION CONTAINER_HOL_DB.PUBLIC.FORECAST (ds array, y array, periods number)
RETURNS variant 
SERVICE=CONTAINER_HOL_DB.PUBLIC.PROPHET_APP     //Snowpark Container Service name
ENDPOINT='prophet-app'   //The endpoint within the container
MAX_BATCH_ROWS=5         //limit the size of the batch
AS '/forecast';           //The API endpoint

--validate 
select parse_json(CONTAINER_HOL_DB.PUBLIC.FORECAST(['2023-01-01','2023-01-02'], [1,2], 1)) as forecast; 


--example usage, with parsing 
--select 
--    date(f.value:ds) as date, 
--    to_decimal(f.value:yhat) as temp 
--from (
--    select 
--        parse_json(CONTAINER_HOL_DB.PUBLIC.FORECAST(ARRAY_AGG(DATE), ARRAY_AGG(TEMP), 7)) as forecast
--    from WEATHER
--    ) as forecasted_data, 
--  lateral flatten(input => forecasted_data.forecast) f
--UNION ALL 
--SELECT * FROM WEATHER 
--order by date desc
;


create or replace procedure build_weather_forecast(period number)
returns varchar 
language SQL 
as 
$$
begin
    create or replace table weather_forecast as 
    (
        select 
            date(f.value:ds) as date, 
            to_decimal(f.value:yhat) as temp 
        from (
            select 
                parse_json(CONTAINER_HOL_DB.PUBLIC.FORECAST(ARRAY_AGG(DATE), ARRAY_AGG(TEMP), :period)) as forecast
            from WEATHER
            ) as forecasted_data, 
          lateral flatten(input => forecasted_data.forecast) f
        UNION ALL 
        SELECT * FROM WEATHER 
        order by date desc
    
    ); 
return 'Weather Forecast created!';
end
$$
; 

call build_weather_forecast(7); 

select * from weather_forecast
order by date desc; 

-------------------------------------
----- 4 - CLEAN UP            ------- 
-------------------------------------

alter service CONTAINER_HOL_DB.PUBLIC.PROPHET_APP suspend; 
drop service CONTAINER_HOL_DB.PUBLIC.PROPHET_APP; 
alter compute pool CONTAINER_HOL_POOL stop all; 
alter compute pool CONTAINER_HOL_POOL suspend; 


