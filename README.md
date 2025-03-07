# ts-spcs-udf
Example of Custom timeseries forecasting running on spcs and being exposed as a snowflake UDTF


# Running 
1. Run admin_user_build_script.sql in your snowflake account as accountadmin or similar. 

2. Login with container_user and run the SETUP section of the container_user_build_script.sql script. 

3. Locally, run the docker_build_script.sh file. Feel free to modify the flask app code as needed. 

4. Upload prophet-app.yaml to your @specs stage 

5. Run the rst of the container_user_build_sript.sql 
