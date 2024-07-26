FROM ultralytics/yolov5:latest-cpu
WORKDIR /usr/src/app
RUN mkdir -p ./downloaded_images
RUN pip install --upgrade pip
COPY requirements.txt .
RUN pip install -r requirements.txt
RUN curl -L https://github.com/ultralytics/yolov5/releases/download/v6.1/yolov5s.pt -o yolov5s.pt

ENV BUCKET_NAME="tf-maayana-images-bucket"
ENV SQS_QUEUE_NAME="tf-maayana-project-queue"
ENV REGION_NAME="eu-north-1"
ENV DYNAMODB_TABLE="tf-maayana-predictions-dynamodb-table"
ENV ALB_URL="maayana-polybot-eu-north-1.int-devops.click:8443"

COPY . .

CMD ["python3", "app.py"]
