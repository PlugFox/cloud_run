# cloud_run
Dart cloud run low level framework

### Hot to run a local instance:

```shell
dart run .\bin\server.dart --port 8080 --concurrency=5
```

### Config Google Cloud Run:

[Installing Google Cloud SDK](https://cloud.google.com/sdk/docs/install)  
```shell
gcloud auth login
gcloud config set core/project PROJECT-NAME
gcloud config set run/platform managed
gcloud config set run/region europe-west4
```

### Deploy:

[gcloud beta run deploy](https://cloud.google.com/sdk/gcloud/reference/beta/run/deploy)  
```shell
gcloud beta run deploy CONTAINER-NAME \
    --source=. \                            # can use $PWD or . for current dir
    --project=PROJECT-NAME \                # the Google Cloud project ID
    --port=8080 \                           # Container port to receive requests at. Also sets the $PORT environment variable.
    --args='--port 8080,--concurrency=5' \  #
    --set-env-vars \                        #
    --concurrency=5 \                       #
    --max-instances=3 \                     #
    --region=europe-west4 \                 # ex: us-central1
    --platform managed \                    # for Cloud Run
    --timeout=25s \                         # Set the maximum request execution time (timeout).
    --cpu=1 \                               # Set a CPU limit in Kubernetes cpu units.
    --memory=64Mi \                         # 
    --no-use-http2 \                        # 
    --connectivity=external \               #
    --allow-unauthenticated                 # for public access
```