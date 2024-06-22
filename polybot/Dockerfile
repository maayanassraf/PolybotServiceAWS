FROM python:alpine3.19
WORKDIR /usr/src/app
RUN pip install --upgrade pip
COPY requirements.txt .
RUN pip install -r requirements.txt

ENV TELEGRAM_APP_URL="https://maayana-polybot-alb-1158443373.eu-north-1.elb.amazonaws.com:443"
ENV BUCKET_NAME="maayana-aws-project-bucket"
ENV SQS_QUEUE_NAME="maayana-aws-project-queue"
ENV REGION_NAME="eu-north-1"
ENV DYNAMODB_TABLE="maayana-aws-project-predictions"

COPY . .

CMD ["python3", "app.py"]