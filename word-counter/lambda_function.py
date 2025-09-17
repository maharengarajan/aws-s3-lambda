# import json
# import boto3
# from datetime import datetime
# import urllib.parse

# s3 = boto3.client('s3')

# def lambda_handler(event, context):
#     bucket = event['Records'][0]['s3']['bucket']['name']
#     key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')

#     try:
#         response = s3.get_object(Bucket=bucket, Key=key)
#         content = response['Body'].read().decode('utf-8')

#         word_count = len(content.split())

#         current_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
#         count_entry = f"File: {key}, Words: {word_count}, Time: {current_time}\n"

#         count_key = 'count/count.txt'
#         existing_content = ''

#         try:
#             existing_response = s3.get_object(Bucket=bucket, Key=count_key)
#             existing_content = existing_response['Body'].read().decode('utf-8')
#         except s3.exceptions.NoSuchKey:
#             pass

#         updated_content = existing_content + count_entry

#         s3.put_object(Bucket=bucket, Key=count_key, Body=updated_content)

#         return {
#             'statusCode': 200,
#             'body': json.dumps(f"Processed file {key} with {word_count} words.")
#         }
#     except Exception as e:
#         return {
#             'statusCode': 500,
#             'body': json.dumps(f"Error processing file {key}: {str(e)}")
#         }

import json
import boto3
import logging
from datetime import datetime
import urllib.parse

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client('s3')

def lambda_handler(event, context):
    logger.info("Lambda triggered with event: %s", json.dumps(event))

    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')

    logger.info("Processing file: %s from bucket: %s", key, bucket)

    try:
        # Get file from S3
        response = s3.get_object(Bucket=bucket, Key=key)
        content = response['Body'].read().decode('utf-8')
        logger.info("Successfully read file %s (%d bytes)", key, len(content))

        # Count words
        word_count = len(content.split())
        logger.info("Word count for file %s: %d", key, word_count)

        # Prepare entry
        current_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        count_entry = f"File: {key}, Words: {word_count}, Time: {current_time}\n"

        # Read existing count.txt if present
        count_key = 'count/count.txt'
        existing_content = ''
        try:
            existing_response = s3.get_object(Bucket=bucket, Key=count_key)
            existing_content = existing_response['Body'].read().decode('utf-8')
            logger.info("Found existing count.txt with length %d", len(existing_content))
        except s3.exceptions.NoSuchKey:
            logger.warning("No existing count.txt found, creating a new one.")

        # Update content
        updated_content = existing_content + count_entry
        s3.put_object(Bucket=bucket, Key=count_key, Body=updated_content)
        logger.info("Updated count.txt successfully with new entry.")

        return {
            'statusCode': 200,
            'body': json.dumps(f"Processed file {key} with {word_count} words.")
        }

    except Exception as e:
        logger.error("Error processing file %s: %s", key, str(e), exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error processing file {key}: {str(e)}")
        }
