import json
import os
import boto3
from datetime import datetime

sns_client = boto3.client("sns")
ecr_client = boto3.client("ecr")

SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
ENVIRONMENT = os.environ.get("ENVIRONMENT", "unknown")


def handler(event, context):
    """
    EventBridge handler: triggered on ECR Image Scan Complete events.
    Publishes SNS alert if CRITICAL vulnerabilities are found.
    """
    try:
        print(f"📥 Event received: {json.dumps(event)}")

        detail = event.get("detail", {})
        repo = detail.get("repository-name", "unknown")
        image_digest = detail.get("image-digest", "unknown")
        scan_status = detail.get("scan-status", "UNKNOWN")

        print(f"Processing scan: repo={repo}, digest={image_digest}, status={scan_status}")

        if scan_status != "COMPLETE":
            print(f"⏳ Scan not complete ({scan_status}), skipping notification")
            return {"status": "skipped", "message": "Scan not complete"}

        # Get actual scan findings from ECR
        try:
            response = ecr_client.describe_image_scan_findings(
                repositoryName=repo,
                imageId={"imageDigest": image_digest}
            )

            findings = response.get("imageScanFindings", {})
            severity_counts = findings.get("findingSeverityCounts", {})

            critical = severity_counts.get("CRITICAL", 0)
            high = severity_counts.get("HIGH", 0)
            medium = severity_counts.get("MEDIUM", 0)
            low = severity_counts.get("LOW", 0)

            print(f"Severity breakdown: CRITICAL={critical}, HIGH={high}, MEDIUM={medium}, LOW={low}")

            # Only alert on CRITICAL (as per buenas_practicas.md security gates)
            if critical > 0:
                message = format_alert_message(repo, image_digest, critical, high, medium, low)
                publish_alert(message, repo)
                print(f"🚨 Alert published: {critical} CRITICAL vulnerabilities found")
                return {"status": "notified", "critical": critical, "high": high}
            else:
                print(f"✅ No CRITICAL vulnerabilities (HIGH={high}, MEDIUM={medium}, LOW={low})")
                return {"status": "ok", "message": "No critical vulnerabilities"}

        except ecr_client.exceptions.ImageNotFoundException:
            print(f"❌ Image not found: {repo}:{image_digest}")
            return {"status": "error", "message": "Image not found"}

    except Exception as e:
        print(f"❌ Error processing scan event: {str(e)}")
        # Publish error alert
        error_msg = f"🔴 ERROR: ECR Scan Handler failed\n\nEnvironment: {ENVIRONMENT}\nError: {str(e)}\n\nTimestamp: {datetime.utcnow().isoformat()}"
        try:
            publish_alert(error_msg, "ecr-scan-handler-error")
        except:
            pass
        return {"status": "error", "message": str(e)}


def format_alert_message(repo, image_digest, critical, high, medium, low):
    """Format alert message for SNS"""
    timestamp = datetime.utcnow().isoformat()

    message = f"""🚨 CRITICAL VULNERABILITIES DETECTED - ECR Image Scan

Environment: {ENVIRONMENT}
Repository: {repo}
Image Digest: {image_digest}
Scan Timestamp: {timestamp}

━━ VULNERABILITY SUMMARY ━━
🔴 CRITICAL:      {critical}
🟠 HIGH:          {high}
🟡 MEDIUM:        {medium}
🔵 LOW:           {low}

⚠️  CRITICAL vulnerabilities found in container image!

ACTION REQUIRED:
1. Review findings in ECR console
2. Update vulnerable dependencies
3. Rebuild image and re-scan
4. Do NOT deploy this image to production

ECR Console: https://console.aws.amazon.com/ecr/repositories/{repo}
    """

    return message.strip()


def publish_alert(message, repo):
    """Publish alert to SNS"""
    try:
        response = sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=f"[{ENVIRONMENT}] 🚨 ECR CRITICAL Vulnerabilities - {repo}",
            Message=message,
        )
        print(f"SNS published: {response['MessageId']}")
        return response
    except Exception as e:
        print(f"❌ Failed to publish SNS: {str(e)}")
        raise
