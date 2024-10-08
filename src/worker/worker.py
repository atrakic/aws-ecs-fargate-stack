import logging
import os
import sys
import json
import botocore
import boto3

logging.basicConfig(stream=sys.stdout, level=logging.INFO)

aws_region = os.getenv("AWS_DEFAULT_REGION", default="us-east-1")

queue_url = os.getenv("QUEUE_URL")
sqs_client = boto3.client("sqs", region_name=aws_region)


def delete_message(message, queue_uri):
    """Deletes a message from the specified queue"""
    try:
        return sqs_client.delete_message(
            QueueUrl=queue_uri, ReceiptHandle=message.get("ReceiptHandle")
        )
    except botocore.exceptions.ClientError as error:
        logging.error("Error deleting message: %s", error)
        return None


def get_messages(queue_uri):
    """
    Long-polls the specified Queue, returning zero up to 10 messages.
    """

    try:
        messages = sqs_client.receive_message(QueueUrl=queue_uri, WaitTimeSeconds=5)
    except botocore.exceptions.ClientError as error:
        logging.error("Error receiving message: %s", error)
        return []

    return messages.get("Messages", [])


def process_message():
    for message in get_messages(queue_url):
        message_body = json.loads(message["Body"])["Message"]
        logging.info("Message received:  %s", message_body)
        delete_message(message, queue_url)


if __name__ == "__main__":
    while True:
        process_message()
