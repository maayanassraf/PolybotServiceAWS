FROM python:alpine3.19
WORKDIR /usr/src/app
RUN pip install --upgrade pip
COPY requirements.txt .
RUN pip install -r requirements.txt

ENV TELEGRAM_APP_URL="https://maayana-polybot-eu-north-1.int-devops.click:443"
ENV BUCKET_NAME="tf-maayana-images-bucket"
ENV SQS_QUEUE_NAME="tf-maayana-project-queue"
ENV REGION_NAME="eu-north-1"
ENV DYNAMODB_TABLE="tf-maayana-predictions-dynamodb-table"
ENV SECRET_ID="tf-telegram-botToken"

COPY . .

CMD ["python3", "app.py"]