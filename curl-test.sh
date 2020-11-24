# request example

curl -s -k -H 'Content-Type: application/json' \
    -X POST \
     -d '{
        "name": "test-007",
        "className": "org.apache.spark.examples.SparkPi",
        "numExecutors": 2,
        "file": "local:///opt/spark/examples/src/main/python/pi.py",
        "args": ["10"],
        "conf": {
            "spark.kubernetes.driver.pod.name" : "spark-pi-driver",
            "spark.kubernetes.container.image": "mikaelapisani/spark-py:1.3",
            "spark.kubernetes.authenticate.driver.serviceAccountName": "spark"
        }
      }' "http://livy-test:8998/batches" 


