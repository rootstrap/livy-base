# request example


kubectl exec --namespace airflow $LIVY_POD -- curl -s -k -H 'Content-Type: application/json' \
    -X POST \
     -d '{
        "name": "test-007",
        "className": "org.apache.spark.examples.SparkPi",
        "numExecutors": 2,
        "file": "local:///opt/spark-3.1.2-bin-hadoop3.2/examples/src/main/python/pi.py",
        "args": ["10"],
        "conf": {
            "spark.kubernetes.driver.pod.name" : "spark-pi-driver",
            "spark.kubernetes.container.image": "rootstrap/spark-py:latest",
            "spark.kubernetes.authenticate.driver.serviceAccountName": "spark"
        }
      }' "http://localhost:8998/batches" 


