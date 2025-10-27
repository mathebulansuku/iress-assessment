import os
import json
import boto3
from collections import defaultdict

s3 = boto3.client("s3")


def top_countries_by_population(records, top_n=3):
    totals = defaultdict(int)
    for r in records:
        try:
            country = r.get("country")
            pop = int(r.get("population", 0))
        except Exception:
            continue
        if country:
            totals[country] += pop
    ordered = sorted(totals.items(), key=lambda x: x[1], reverse=True)[:top_n]
    return [{"country": c, "total_population": p} for c, p in ordered]


def handler(event, context):
    bucket = os.environ.get("DATASET_BUCKET")
    key = os.environ.get("DATASET_KEY", "cities.json")

    if not bucket:
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "DATASET_BUCKET not configured"}),
        }

    try:
        obj = s3.get_object(Bucket=bucket, Key=key)
        body = obj["Body"].read()
        records = json.loads(body)
        result = top_countries_by_population(records, top_n=3)
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"top_countries": result}),
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": str(e)}),
        }

