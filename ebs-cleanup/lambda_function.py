import boto3
import logging
from datetime import datetime, timezone, timedelta

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.client("ec2")

# Retention period in days
RETENTION_DAYS = 14

def lambda_handler(event, context):
    """
    Lambda function to delete EBS snapshots older than RETENTION_DAYS.
    Triggered weekly by CloudWatch Events.
    """

    try:
        account_id = boto3.client("sts").get_caller_identity()["Account"]
        logger.info(f"Running EBS cleanup for account {account_id}")

        # Calculate cutoff date
        cutoff = datetime.now(timezone.utc) - timedelta(days=RETENTION_DAYS)

        # Get all snapshots owned by this account
        snapshots = ec2.describe_snapshots(OwnerIds=[account_id])["Snapshots"]

        deleted = []
        skipped = []

        for snapshot in snapshots:
            snapshot_id = snapshot["SnapshotId"]
            start_time = snapshot["StartTime"]

            if start_time < cutoff:
                try:
                    ec2.delete_snapshot(SnapshotId=snapshot_id)
                    logger.info(f"Deleted snapshot {snapshot_id}, created at {start_time}")
                    deleted.append(snapshot_id)
                except Exception as e:
                    logger.error(f"Failed to delete snapshot {snapshot_id}: {str(e)}")
            else:
                skipped.append(snapshot_id)

        logger.info(f"Cleanup complete. Deleted: {len(deleted)}, Skipped: {len(skipped)}")
        return {
            "status": "success",
            "deleted_count": len(deleted),
            "skipped_count": len(skipped),
            "deleted_snapshots": deleted,
        }

    except Exception as e:
        logger.exception("Error during EBS snapshot cleanup")
        return {"status": "error", "message": str(e)}
