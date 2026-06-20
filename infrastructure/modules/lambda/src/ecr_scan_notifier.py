import json
import os
import boto3

sns = boto3.client("sns")
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
ENVIRONMENT = os.environ.get("ENVIRONMENT", "unknown")


def handler(event, context):
    detail = event.get("detail", {})
    repo = detail.get("repository-name", "unknown")
    tag = detail.get("image-tags", ["unknown"])[0]
    findings = detail.get("finding-severity-counts", {})

    critical = findings.get("CRITICAL", 0)
    high = findings.get("HIGH", 0)

    if critical == 0 and high == 0:
        return {"status": "ok", "message": "No critical/high findings"}

    message = (
        f"⚠️ Vulnerabilidades detectadas en ECR — RetailStore [{ENVIRONMENT}]\n\n"
        f"Repositorio: {repo}\n"
        f"Tag: {tag}\n"
        f"CRITICAL: {critical}\n"
        f"HIGH: {high}\n\n"
        f"Revisar: https://console.aws.amazon.com/ecr/repositories/{repo}"
    )

    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject=f"[{ENVIRONMENT.upper()}] ECR Scan: {critical} CRITICAL, {high} HIGH en {repo}:{tag}",
        Message=message,
    )

    return {"status": "notified", "critical": critical, "high": high}
