Iress Assessment — Terraform, API, and Frontend

This repo provisions a small serverless stack on AWS and a minimal frontend to display the most popular countries by total population computed from a dataset in S3. I built it end‑to‑end with Terraform, and used Codex as an assistant for troubleshooting, automation, and scaffolding.

**What It Deploys**
- HTTP API (API Gateway v2) integrated with a Lambda function that:
- Reads a JSON dataset from S3
- Aggregates population by country and returns the top results
- Also serves a tiny HTML UI at `/` and `/ui` (no CloudFront required)
- S3 bucket holding the dataset (and uploads `dataset/cities.json`)
- Optional S3 static website for a simple frontend (kept private by default, to respect account-level Block Public Access)
- Remote Terraform state in S3 with DynamoDB state locking

**Key Files**
- Backend config and modules wiring: `main.tf:11`
- API URL output: `outputs.tf:9`
- Lambda handler (returns JSON and serves the UI): `src/index.py:23`

**Prerequisites**
- Terraform >= 1.5
- AWS account/credentials with permissions to create the resources listed above
- Default region: `af-south-1` (configurable via variable)

**How I Solved the Remote State Bootstrap**
When I first ran `terraform plan`, backend initialization failed because the S3 bucket and DynamoDB table for the remote backend didn’t exist yet. Terraform configures backends before creating resources, so we need a short bootstrap phase.

What I did (with Codex guiding and executing):
- Initialize locally and create backend infra
  - Clean the working directory (drop any remembered backend):
    - PowerShell: `Remove-Item -Recurse -Force .terraform -ErrorAction SilentlyContinue; Remove-Item -Force .terraform.lock.hcl, terraform.tfstate, terraform.tfstate.backup -ErrorAction SilentlyContinue`
  - Disable backend temporarily (Codex commented it, then re‑enabled later), then:
    - `terraform init -backend=false`
    - `terraform plan -out=tfplan -lock=false -target="aws_s3_bucket.tf_state" -target="aws_dynamodb_table.tf_lock"`
    - `terraform apply -auto-approve "tfplan"`
    - If the DynamoDB table already existed, we imported it: `terraform import aws_dynamodb_table.tf_lock iress-assessment-tf-locks`
- Re‑enable the backend and migrate state
  - To avoid a digest mismatch, Codex switched to a new key (`env/dev/terraform.tfstate`) in `main.tf:13`
  - `terraform init -migrate-state -force-copy`
- Verify and continue as normal
  - `terraform plan`

Notes
- Backend block (S3) is in `main.tf:11`
- Provider region is variable-driven (default `af-south-1`): `main.tf:20`

**Handling Pre‑existing Resources**
- IAM Role existed already: imported it so Terraform wouldn’t recreate it
  - `terraform import 'module.lambda.aws_iam_role.this[0]' iress-hello-role`
- Lambda permission already existed for API Gateway: imported, then Terraform replaced it with current API id
  - `terraform import 'module.api_gateway.aws_lambda_permission.apigw_invoke[0]' 'arn:aws:lambda:af-south-1:<acct>:function:iress-hello/AllowAPIGatewayInvoke'`

**Deploy**
- Initialize and apply:
  - `terraform init`
  - `terraform apply`
- Outputs (examples):
  - API base URL: `terraform output -raw api_url`
  - Frontend website bucket: `terraform output -raw frontend_bucket`
  - Frontend website endpoint (may be blocked by account public access): `terraform output -raw frontend_url`

**Using The API**
- JSON endpoint: `${api_url}/hello`
- Inline UI (served by Lambda): `${api_url}/ui` or `${api_url}/`
  - The HTML page fetches `./hello` and renders the top countries.

Implementation notes
- UI in Lambda: see `src/index.py:23`
- API module outputs include the API endpoint and an invoke URL that accounts for the stage: `modules/api-gateway/outputs.tf:23`

**Optional Static Frontend (S3)**
A minimal static app is also included in `frontend/` with a helper script to point it at your API.

- Files:
  - HTML/CSS/JS: `frontend/index.html`, `frontend/style.css`, `frontend/app.js`
  - Example config: `frontend/config.example.js`
  - Script to generate `frontend/config.js` from Terraform output: `scripts/generate_frontend_config.ps1:1`
- Generate config and open locally:
  - `powershell ./scripts/generate_frontend_config.ps1`
  - Then open `frontend/index.html` in your browser (or serve via a static server)
- Terraform module for S3 website (private by default): `modules/s3-website`
  - You can set it public by enabling bucket policy and ensuring account-level Block Public Access allows it (`public_read = true`). I kept it off per the “no CloudFront” and security requirements.

**Variables You Can Tweak**
- Region and backend
  - `variables.tf:1` (via `var.aws_region`)
  - Backend S3 config in `main.tf:11` (string values)
- Names and prefixes
  - State bucket: `variables.tf` → `tf_state_bucket_name`
  - Lock table: `variables.tf` → `tf_lock_table_name`
  - Dataset bucket prefix: `variables.tf` → `dataset_bucket_prefix`
  - Frontend bucket prefix: `variables.tf` → `frontend_bucket_prefix`
- API/Lambda behavior
  - Lambda name and dataset key: `variables.tf` → `lambda_name`, `lambda_dataset_key`
  - API name, stage, and route: `variables.tf` → `api_*`

**Troubleshooting**
- “S3 bucket does not exist” or backend init loops
  - Initialize locally and create the bucket/table, then migrate state (see the Bootstrap section above)
- DynamoDB digest mismatch
  - Use a fresh state key (e.g., `env/dev/terraform.tfstate`) and `terraform init -migrate-state -force-copy`
- EntityAlreadyExists for IAM Role or Lambda permission
  - Import the existing resource and rerun `terraform plan`
- S3 website 403 with PutBucketPolicy
  - Account-level Block Public Access prevents public policies. Use the Lambda-served UI (`/ui`) or host the static site elsewhere.

**How I Used Codex As An Assistant**
Codex acted as a terminal-based coding partner that:
- Analyzed Terraform configuration to identify the bootstrap deadlock (backend initializes before resources)
- Executed targeted plans/applies to create backend infra safely
- Migrated local → S3 state and resolved a DynamoDB digest mismatch by changing the state key
- Imported pre‑existing IAM/Lambda permission resources into state to avoid conflicts
- Added helpful outputs (API URL) and a small frontend
- Implemented a no‑CloudFront option by serving a tiny HTML UI directly from Lambda
- Created a reusable S3 website module kept private by default
- Committed changes as small, logical Git commits using my identity

Codex’s contributions were surgical and auditable: it prefaced terminal actions, updated files via patch, used imports when appropriate, and verified results with plans before applies.

**Cleanup**
- Remove resources: `terraform destroy`
- Optional safety: uncomment `prevent_destroy` for the backend state bucket and lock table in `main.tf`

**Repository Structure (short)**
- Terraform root and modules
  - `main.tf:11`, `variables.tf:1`, `outputs.tf:1`
  - `modules/api-gateway`, `modules/lambda`, `modules/s3-data`, `modules/s3-website`
- Lambda code: `src/index.py:23`
- Frontend: `frontend/`
- Helper: `scripts/generate_frontend_config.ps1:1`

If you want me to add API CORS settings or make the S3 website publicly accessible in a controlled way, I can wire that in too.
