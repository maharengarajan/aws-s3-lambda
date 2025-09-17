import boto3
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.client("ec2")

def lambda_handler(event, context):
    """
    Lambda function to start/stop EC2 instances.
    It finds instances tagged with Environment=dev or Environment=development.
    """

    logger.info(f"Received event: {event}")

    action = event.get("action")

    if action not in ["start", "stop"]:
        logger.error(f"Invalid action received: {action}")
        return {"status": "error", "message": f"Invalid action: {action}"}

    try:
        # Find EC2 instances with Environment=dev or development
        response = ec2.describe_instances(
            Filters=[
                {"Name": "tag:Environment", "Values": ["dev", "development"]},
                {"Name": "instance-state-name", "Values": ["running", "stopped"]}
            ]
        )

        # Extract all instance IDs
        instance_ids = [
            instance["InstanceId"]
            for reservation in response["Reservations"]
            for instance in reservation["Instances"]
        ]

        logger.info(f"Matching instances: {instance_ids}")

        if not instance_ids:
            logger.info("No matching instances found. Nothing to do.")
            return {"status": "success", "message": "No matching instances found."}

        # Perform action
        if action == "start":
            ec2.start_instances(InstanceIds=instance_ids)
            logger.info(f"Started instances: {instance_ids}")
            return {"status": "success", "action": "start", "instances": instance_ids}

        elif action == "stop":
            ec2.stop_instances(InstanceIds=instance_ids)
            logger.info(f"Stopped instances: {instance_ids}")
            return {"status": "success", "action": "stop", "instances": instance_ids}

    except Exception as e:
        logger.exception("Error while processing EC2 scheduler Lambda")
        return {"status": "error", "message": str(e)}
