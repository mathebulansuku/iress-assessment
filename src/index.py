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

    # Detect path for simple inline UI served via API Gateway (no CloudFront/S3 website required)
    path = (
        (event.get("requestContext", {}).get("http", {}).get("path"))
        if isinstance(event, dict)
        else None
    ) or event.get("rawPath") if isinstance(event, dict) else None

    if path in ("/", "/ui"):
        html = """
<!doctype html>
<html><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>Popular Countries</title>
<style>body{font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif;background:#0b1020;color:#e8eefc;margin:0;padding:24px} .wrap{max-width:800px;margin:0 auto;background:#121932;border:1px solid #233057;border-radius:12px;box-shadow:0 10px 30px rgba(0,0,0,.35);padding:24px} h1{margin:0 0 8px} .muted{color:#a8b3cf} ul{list-style:none;padding:0;display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:12px} li{background:#0f1733;border:1px solid #1f2c55;border-radius:10px;padding:14px} .name{font-weight:600;margin-bottom:6px} .pop{color:#a8b3cf;font-size:14px} .err{background:#2a0f18;border:1px solid #7f3040;padding:10px 12px;border-radius:8px}</style>
</head><body><div class=\"wrap\"><h1>Most Popular Countries</h1><p class=\"muted\">Top total population from dataset.</p><div id=\"status\"></div><ul id=\"list\"></ul></div>
<script>
const st = document.getElementById('status');
const ul = document.getElementById('list');
function fmt(n){try{return new Intl.NumberFormat().format(n)}catch(e){return String(n)}}
async function run(){
  try{
    const res = await fetch('./hello');
    if(!res.ok) throw new Error('HTTP '+res.status);
    const data = await res.json();
    const arr = (data && data.top_countries) || [];
    if(!Array.isArray(arr)||arr.length===0){ st.innerHTML = '<div class="err">No data.</div>'; return; }
    st.textContent='';
    ul.innerHTML='';
    arr.forEach(it=>{
      const li=document.createElement('li');
      li.innerHTML=`<div class="name">${it.country}</div><div class="pop">Total population: ${fmt(it.total_population)}</div>`;
      ul.appendChild(li);
    });
  }catch(e){ st.innerHTML = '<div class="err">Failed: '+e.message+'</div>'; }
}
run();
</script></body></html>
"""
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "text/html"},
            "body": html,
        }

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
