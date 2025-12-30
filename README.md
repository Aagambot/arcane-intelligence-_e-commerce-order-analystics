# 🌌 Arcane Intelligence: High-Fidelity Order Analytics
Website : https://arcane-intelligence.lovable.app/

**Arcane Intelligence** is a production-ready, cloud-native fintech analytics platform. It provides e-commerce teams with a real-time command center for monitoring revenue trends and order health through a serverless AWS architecture.


## 🛠️ Architecture Overview
The system follows a modular, serverless design pattern managed entirely via **Infrastructure as Code (Terraform)**.

* **Frontend**: React-based "Fintech Dark" dashboard hosted on Lovable.
* **API Layer**: AWS API Gateway (REST) with MOCK CORS integration for secure cross-origin communication.
* **Compute**: AWS Lambda functions for order processing and daily report generation.
* **Storage**: 
    * **DynamoDB**: Low-latency storage for real-time dashboard metrics.
    * **S3**: Data lake for long-term raw JSON order archival.
* **Notifications**: Automated daily revenue reports via AWS SES.

## 📁 Project Structure
The repository is organized into independent, reusable Terraform modules:
- `00-foundation/`: Core networking and security groups.
- `01-iam/`: Least-privilege IAM roles and policies.
- `02-storage/`: S3 buckets and DynamoDB tables.
- `03-api-ingestion/`: API Gateway and the core Order Processor Lambda.
- `04-event-processing/`: EventBridge rules for scheduled report generation.
- `05-notification/`: SES/SNS configuration for alerts.
- `06-monitoring/`: CloudWatch dashboards and alarms.

## 🚀 Getting Started

### Prerequisites
- AWS CLI configured with administrator access.
- Terraform v1.5.0+ installed.

### Deployment Order
Deploy the modules in the following sequence to respect dependency chains:
1. `01-iam`
2. `02-storage`
3. `03-api-ingestion`
4. `04-event-processing`
5. `05-notification`
6. `06-monitoring`

```bash
cd 01-iam
terraform init
terraform apply