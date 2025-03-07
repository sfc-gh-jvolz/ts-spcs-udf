#local build
docker build --platform=linux/arm64/v8 -t prophet-app:latest . 


#validate locally
docker images 

docker run -d -p 9090:9090 prophet-app:latest

curl -X POST -H "Content-Type: application/json" -d '{"data": [["01-01-2020","01-02-2020","01-03-2020","01-04-2020","01-05-2020"], [10,10,11,11,10], 3]}' http://localhost:9090/forecast

docker container list 

docker stop <container name> 


#build for snowflake
docker build --platform=linux/amd64 -t sfsenorthamerica-gs-hol.registry.snowflakecomputing.com/container_hol_db/public/image_repo/prophet-app:latest . 

#push image to snowflake repo 
docker login sfsenorthamerica-gs-hol.registry.snowflakecomputing.com/container_hol_db/public/image_repo -u container_user

docker push sfsenorthamerica-gs-hol.registry.snowflakecomputing.com/container_hol_db/public/image_repo/prophet-app:latest 