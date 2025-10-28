# Iress Assessment — Terraform, API, and Frontend

This repo provisions a small serverless stack on AWS and a minimal frontend to display the most popular countries by total population computed from a dataset in S3. I built it end-to-end with Terraform, and used Codex as an assistant for troubleshooting, automation, and scaffolding.

## What It Deploys
- HTTP API (API Gateway v2) integrated with a Lambda function that:
  - Reads a JSON dataset from S3
  - Aggregates population by country and returns the top results
  - Also serves a tiny HTML UI at `/` and `/ui` (no CloudFront required)
- S3 bucket holding the dataset (and uploads `dataset/cities.json`)
- Optional S3 static website for a simple frontend (kept private by default, to respect account-level Block Public Access)
- Remote Terraform state in S3 with DynamoDB state locking

## Setup (Quick Start)
Prereqs
- Terraform >= 1.5
- AWS credentials with permissions for S3, Lambda, API Gateway, IAM, DynamoDB
- Default region is `af-south-1` (override via `-var="aws_region=..."` if needed)

Steps
1) Initialize and apply:
   - `terraform init`
   - `terraform apply`
2) Grab outputs:
   - API URL: `terraform output -raw api_url`
   - Frontend (S3 website) bucket: `terraform output -raw frontend_bucket`
   - Frontend (S3 website) endpoint: `terraform output -raw frontend_url`
3) Try the API:
   - JSON: `${api_url}/hello`
   - Inline UI: `${api_url}/ui` (or `${api_url}/`)

If the S3 website needs to be public, you must first allow it at the AWS account level (S3 Block Public Access), or use the API-served UI at `/ui`.

## Bootstrap Notes (Remote State)
On first run, remote state (S3/DynamoDB) may not exist yet. Backends initialize before resources, so bootstrap is needed. What I did with Codex’s help:
- Initialize locally and create backend infra
  - Clean working dir (drop remembered backend):
    - PowerShell: `Remove-Item -Recurse -Force .terraform -ErrorAction SilentlyContinue; Remove-Item -Force .terraform.lock.hcl, terraform.tfstate, terraform.tfstate.backup -ErrorAction SilentlyContinue`
  - Disable backend temporarily, then:
    - `terraform init -backend=false`
    - `terraform plan -out=tfplan -lock=false -target="aws_s3_bucket.tf_state" -target="aws_dynamodb_table.tf_lock"`
    - `terraform apply -auto-approve "tfplan"`
    - If the DynamoDB table already existed, import it: `terraform import aws_dynamodb_table.tf_lock iress-assessment-tf-locks`
- Re-enable the backend and migrate state
  - To avoid a digest mismatch, switch to a fresh key (e.g., `env/dev/terraform.tfstate` in `main.tf:13`)
  - `terraform init -migrate-state -force-copy`
- Verify: `terraform plan`

## Design Rationale
- Remote state with locking
  - S3 for state + DynamoDB locks to prevent concurrent writes; versioning + SSE on the state bucket for safety.
- HTTP API (API Gateway v2)
  - Lower cost and simpler than REST API for this use case; `$default` stage for minimal setup.
- Lambda + S3 dataset
  - Stateless function reads `dataset/cities.json` and aggregates by `country` → `population` fields.
- Minimal frontend options
  - Inline UI from Lambda at `/ui` avoids S3 public website and CloudFront, matching “no CloudFront” requirement.
  - A reusable S3 website module exists but is private by default due to typical account-level Block Public Access.
- Modularity and portability
  - Variables drive names/regions; modules (`api-gateway`, `lambda`, `s3-data`, `s3-website`) keep concerns isolated.
- Operations hygiene
  - Clear outputs (`api_url`, website info), small targeted imports for pre-existing resources (IAM role, Lambda permission).

## Assumptions
- You have AWS credentials pointing to the intended account in `af-south-1` (or you override the region).
- S3 bucket names must be globally unique; defaults may need overrides in multi-tenant environments.
- The dataset `dataset/cities.json` contains records with `country` and `population` (coercible to integer).
- Account-level S3 Block Public Access is enabled (common default). Public websites require changing that, which we avoided.
- Using AWS-managed policies (e.g., `AWSLambdaBasicExecutionRole`) is acceptable for this exercise.
- Keeping costs minimal (no CloudFront, on-demand DynamoDB, small Lambda package).

## Using The API
- JSON endpoint: `${api_url}/hello`
- Inline UI (served by Lambda): `${api_url}/ui` or `${api_url}/`
  - The HTML page fetches `./hello` and renders the top countries.

## Optional Static Frontend (S3)
The `frontend/` folder includes a static app and a helper to point it at your API.

- Files:
  - `frontend/index.html`, `frontend/style.css`, `frontend/app.js`
  - Example config: `frontend/config.example.js`
  - Generator: `scripts/generate_frontend_config.ps1`
- Generate config and open locally:
  - `powershell ./scripts/generate_frontend_config.ps1`
  - Open `frontend/index.html` directly or via any static file server
- Terraform module for S3 website: `modules/s3-website` (private by default)
  - To make public, set `public_read = true` and ensure account-level settings allow it.

## Variables You Can Tweak
- Region and backend
  - `variables.tf:1` (via `var.aws_region`)
  - Backend strings in `main.tf:11` (bucket, key, region, DynamoDB table)
- Names and prefixes
  - State bucket: `tf_state_bucket_name`
  - Lock table: `tf_lock_table_name`
  - Dataset bucket prefix: `dataset_bucket_prefix`
  - Frontend bucket prefix: `frontend_bucket_prefix`
- API/Lambda behavior
  - Lambda: `lambda_name`, `lambda_dataset_key`, optional `source_dir`
  - API: `api_name`, `api_stage_name`, `api_integrate_lambda`, `api_lambda_route_path`, `api_lambda_method`

## Troubleshooting
- “S3 bucket does not exist” during init
  - Use the bootstrap flow above (local init, targeted create, then migrate).
- DynamoDB digest mismatch
  - Use a new state `key` and `terraform init -migrate-state -force-copy`.
- EntityAlreadyExists (IAM role or Lambda permission)
  - Import the existing resource and re-run `terraform plan`.
- S3 website 403 (PutBucketPolicy)
  - Account-level Block Public Access is on; either change account settings or serve UI from the API (`/ui`).

## How I Used Codex As An Assistant
Codex acted as a terminal-based coding partner that:
- Analyzed the Terraform configuration to identify the bootstrap deadlock
- Executed targeted plans/applies to create backend infra
- Migrated local → S3 state using a new key to resolve a digest mismatch
- Imported pre-existing IAM and Lambda permission resources
- Added outputs and a small frontend; implemented a “no CloudFront” inline UI
- Created a reusable S3 website module (kept private by default)
- Committed changes as small, logical Git commits using my identity

## Cleanup
- Remove resources: `terraform destroy`
- Optional safety: uncomment `prevent_destroy` for the backend state bucket and lock table in `main.tf`

## Repository Structure (short)
- Terraform root and modules
  - `main.tf:11`, `variables.tf:1`, `outputs.tf:1`
  - `modules/api-gateway`, `modules/lambda`, `modules/s3-data`, `modules/s3-website`
- Lambda code: `src/index.py:23`
- Frontend: `frontend/`
- Helper: `scripts/generate_frontend_config.ps1:1`

If you want me to add API CORS settings or make the S3 website publicly accessible in a controlled way, I can wire that in too.
