# livy-base

Expose Apache Livy API to execute spark jobs in a Kubernetes cluster. 
Docker Image available at rootstrap/apache-livy. 

# Install Spark

# Build images 

1. Download spark 
```bash
    wget https://downloads.apache.org/spark/spark-3.1.2/spark-3.1.2-bin-hadoop3.2.tgz .
```

2. Build python Image 
```bash
    cd spark-3.1.2-bin-hadoop3.2
    ./bin/docker-image-tool.sh -r rootstrap -t 3.1.2 -p ./kubernetes/dockerfiles/spark/bindings/python/Dockerfile build
```

# Test 

```bash
	export CLUSTER_URL=$(kubectl cluster-info | grep "Kubernetes master" | awk '{print $6}')
docker run --env SPARK_MASTER_ENDPOINT="k8s://$CLUSTER_URL" --env SPARK_MASTER_PORT="443" --env DEPLOY_MODE="cluster" rootstrap/apache-livy:latest 
```

```bash
curl -s -k -H 'Content-Type: application/json' \
    -X POST \
     -d '{
        "name": "test",
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
```


# Install Apache Livy on Kubernetes Cluster

1. Edit file livy-deployment.yaml with the CLUSTER_URL value 

```bash
    export CLUSTER_URL=$(kubectl cluster-info | grep "Kubernetes master" | awk '{print $6}')
```

2. Create service account       
```bash
    kubectl create serviceaccount spark --namespace airflow
```
3. Create cluster role     
```bash
	kubectl create clusterrolebinding spark-role --clusterrole=edit  --serviceaccount=airflow:spark --namespace=airflow
```
4. Create livy app 
```bash
kubectl apply --namespace airflow -f livy-deployment.yaml
```
5. Check livy is working 
```bash
kubectl get pods | grep livy 
```
* Check spark cluster is functioning: 

1. Run a spark task with spark-submit      


```bash
export LIVY_POD=$(kubectl get pods | grep livy | awk '{print $1}')
kubectl exec -ti --namespace airflow  $LIVY_POD -- bash 
```
```bash
/opt/spark-3.1.2-bin-hadoop3.2/bin/spark-submit  --master $SPARK_MASTER_ENDPOINT \
     --deploy-mode cluster \
     --name spark-test \
     --class org.apache.spark.examples.SparkPi \
     --conf spark.kubernetes.authenticate.driver.serviceAccountName=spark \
     --conf spark.kubernetes.container.image=rootstrap/spark-py:latest \
     --conf spark.kubernetes.authenticate.caCertFile=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt  \
     --conf spark.kubernetes.authenticate.oauthTokenFile=/var/run/secrets/kubernetes.io/serviceaccount/token  \
     --conf spark.kubernetes.file.upload.path=file:///tmp \
     --conf spark.kubernetes.namespace=airflow \
     local:///opt/spark/examples/src/main/python/pi.py 10
``` 
2. Validate that the spark-driver is running: 

```bash
    kubectl get pods | grep driver  
```

* Check Apache Livy is working: 

1. Make a request to run a pyspark job 

```bash

kubectl exec --namespace airflow $LIVY_POD -- curl -s -k -H 'Content-Type: application/json' \
    -X POST \
     -d '{
        "deploy-mode" : "cluster",
        "name": "spark-test",
        "className": "org.apache.spark.examples.SparkPi",
        "numExecutors": 2,
        "file": "local:///opt/spark-3.1.2-bin-hadoop3.2/examples/src/main/python/pi.py",
        "args": ["10"],
        "conf": {
            "spark.kubernetes.authenticate.driver.serviceAccountName" :"spark",
            "spark.kubernetes.container.image": "rootstrap/spark-py:latest",
            "spark.kubernetes.authenticate.caCertFile": "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt",
            "spark.kubernetes.authenticate.oauthTokenFile=/var/run/secrets/kubernetes.io/serviceaccount/token", 
            "spark.kubernetes.file.upload.path": "file:///tmp",
            "spark.kubernetes.namespace": "airflow", 
            "spark.yarn.appMasterEnv.PYSPARK_PYTHON": "pyspark3",
            "spark.kubernetes.driver.pod.name" : "spark-pi-driver",
        }
      }' "http://localhost:8998/batches" 
```

2. Port Forwarding for Apache Livy web:

```bash
	kubectl port-forward $LIVY_POD  8998:8998
```

Enter at [http://localhost:8998](http://localhost:8998)

2. 
```bash
curl -X POST -d '{"kind": "pyspark"}' -H "Content-Type: application/json" http://livy-api:8998/sessions
curl http://livy-api:8998/sessions/0/statements -X POST -H 'Content-Type: application/json' -d '{"code":"1 + 1"}'
```

