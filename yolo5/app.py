import time
from pathlib import Path
from detect import run
import yaml
import json
from loguru import logger
import os
import requests
import boto3

images_bucket = os.environ['BUCKET_NAME']
queue_name = os.environ['SQS_QUEUE_NAME']

sqs_client = boto3.client('sqs', region_name='eu-north-1')

with open("data/coco128.yaml", "r") as stream:
    names = yaml.safe_load(stream)['names']


def consume():
    while True:
        response = sqs_client.receive_message(QueueUrl=queue_name, MaxNumberOfMessages=1, WaitTimeSeconds=5)

        if 'Messages' in response:
            message = response['Messages'][0]['Body']
            message = json.loads(message)
            receipt_handle = response['Messages'][0]['ReceiptHandle']

            # Use the ReceiptHandle as a prediction UUID
            prediction_id = response['Messages'][0]['MessageId']

            logger.info(f'prediction: {prediction_id}. start processing')

            # Receives a URL parameter representing the image to download from S3
            img_name = message['img_name']  # TODO extract from `message`
            chat_id = message['chat_id']  # TODO extract from `message`
            # TODO download img_name from S3, store the local image path in original_img_path
            download_path = '/usr/src/app/downloaded_images'
            s3_client = boto3.client('s3')
            print(f'images/{img_name}')
            s3_client.download_file(
                Bucket=f'{images_bucket}',
                Key=f'images/{img_name}',
                Filename=f'{download_path}/{img_name}'
            )
            original_img_path = f'{download_path}/{img_name}'

            logger.info(f'prediction: {prediction_id}{original_img_path}. Download img completed')

            # Predicts the objects in the image
            run(
                weights='yolov5s.pt',
                data='data/coco128.yaml',
                source=original_img_path,
                project='static/data',
                name=prediction_id,
                save_txt=True
            )

            logger.info(f'prediction: {prediction_id}{original_img_path}. done')

            # This is the path for the predicted image with labels
            # The predicted image typically includes bounding boxes drawn around the detected objects, along with class labels and possibly confidence scores.
            predicted_img_path = Path(f'static/data/{prediction_id}{original_img_path}')

            # TODO Uploads the predicted image (predicted_img_path) to S3 (be careful not to override the original image).
            s3_client.put_object(
                Body=f'{predicted_img_path}',
                Bucket=f'{images_bucket}',
                Key=f'predicted_images/{img_name}'
            )

            # Parse prediction labels and create a summary
            pred_summary_path = Path(f'static/data/{prediction_id}/labels{original_img_path.split(".")[0]}.txt')
            if pred_summary_path.exists():
                with open(pred_summary_path) as f:
                    labels = f.read().splitlines()
                    labels = [line.split(' ') for line in labels]
                    labels = [{
                        'class': names[int(l[0])],
                        'cx': str(float(l[1])),
                        'cy': str(float(l[2])),
                        'width': str(float(l[3])),
                        'height': str(float(l[4])),
                    } for l in labels]

                logger.info(f'prediction: {prediction_id}/{original_img_path}. prediction summary:\n\n{labels}')

                prediction_summary = {
                    'prediction_id': prediction_id,
                    'original_img_path': original_img_path,
                    'predicted_img_path': str(predicted_img_path),
                    'labels': labels,
                    'time': str(time.time()),
                    'chat_id': chat_id
                }

                # TODO store the prediction_summary in a DynamoDB table
                dynamodb = boto3.resource('dynamodb')
                table = dynamodb.Table('maayana-aws-project-predictions')

                table.put_item(
                    Item=prediction_summary
                )

                # TODO perform a GET request to Polybot to `/results` endpoint ?POST
                result = requests.post(f'http://polybot:8443/results?predictionId={prediction_id}')

            # Delete the message from the queue as the job is considered as DONE
            sqs_client.delete_message(QueueUrl=queue_name, ReceiptHandle=receipt_handle)


if __name__ == "__main__":
    consume()
