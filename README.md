**AWS Support Ticket Platform**



A support-ticket application built to practice cloud engineering and DevOps on AWS.



Users can create tickets, view tickets, and mark them as resolved.



This personal project focuses on infrastructure automation, application deployment, monitoring, and recovery testing.



**Tools Used and Architecture**



```text

                         **USERS**

                           |

                           v

              **APPLICATION LOAD BALANCER**

              Routes incoming HTTP

              requests to the application

                           |

                           v

                     **ECS FARGATE**

              Runs the containerized Flask

              application without managing

              underlying servers

                           |

              +------------+------------+

              |                         |

              v                         v

       **RDS POSTGRESQL             SECRETS MANAGE**R

       Stores support             Stores database

       tickets and                credentials

       application data



\-------------------------------------------------------

                    **CI/CD PIPELINE**

\-------------------------------------------------------



                    **PYTHON + FLASK**

                 Application source code

                           |

                           v

                    **GITHUB ACTIONS**

               Runs checks and deployment

                           |

                           v

                        **DOCKER**

              Builds the application image

                           |

                           v

                      **AMAZON ECR**

              Stores the application image

                           |

                           v

                     **ECS FARGATE**

              Runs the application container



\-------------------------------------------------------

              **INFRASTRUCTURE & MONITORING**

\-------------------------------------------------------



                       **TERRAFORM**

         Defines and manages AWS infrastructure



                   **AMAZON CLOUDWATCH**

         Collects application logs for troubleshooting

```



The load balancer sends visitor requests to the application. The application reads and saves tickets in the database.



GitHub Actions builds and deploys application changes. The Secrets Manager branch represents credential access, not visitor traffic.



**Infrastructure and Deployment**



**Infrastructure**



**Terraform defines:**



\- A VPC, subnets, and network routes.

\- Security groups controlling network access.

\- A load balancer, listener, and target group.

\- An ECS cluster, application service, and task definition.

\- An ECR image repository.

\- An RDS database and database subnet group.

\- A separate ECS task for database setup.

\- A Secrets Manager secret for application database credentials.

\- IAM roles and policies.

\- A CloudWatch log group.



Terraform stores its state in S3 with encryption and state locking configured.



**Application Deployment**



The deployment workflow starts when changes reach main. It can also be started manually on main.



**The workflow**:



1\. Runs the project checks.

2\. Builds a Docker image.

3\. Scans for high and critical vulnerabilities with available fixes.

4\. Obtains temporary AWS access.

5\. Uploads the image to ECR with a unique version tag.

6\. Updates the ECS service.

7\. Waits for service stability.

8\. Confirms the expected task definition is deployed.

9\. Checks that the load balancer reports a healthy application target.



The vulnerability scan stops deployment if it finds matching vulnerabilities.



Workflow: [Application deployment](.github/workflows/deploy.yml)



**Security**



\- The load balancer accepts HTTP requests only from the configured public IP address.

\- The application accepts requests only from the load balancer.

\- Database connections are restricted to resources using the application security group.

\- Public access to RDS is disabled.

\- Database storage is encrypted.

\- RDS manages the database administrator password.

\- The deployment workflow uses temporary AWS credentials.



Browser access currently uses HTTP.



**Monitoring**



The application is configured to send logs to CloudWatch. These logs support troubleshooting and investigation of application errors.



Dashboards and automated alerts are not defined in the current Terraform configuration.



**Testing and Recovery**



**Database Recovery**



A snapshot was restored to a separate recovery database.



The restored database contained the expected ticket titled "Snapshot recovery test." The check passed, confirming that the snapshot preserved that record.



This test did not verify every database record.



Evidence: [Database recovery report](docs/evidence/database-recovery.txt)



**Database Protection**



**Terraform configures:**



\- Seven days of automated backup retention.

\- Encrypted database storage.

\- Database deletion protection.

\- A required final snapshot when deleting the database.



**Setup and Cleanup**



**Run Locally**



Install Git and Docker Desktop. Start Docker Desktop before continuing.



**1. Download the project**



```powershell

git clone https://github.com/waliu44/aws-support-ticket-platform.git

cd aws-support-ticket-platform

```



If the project is already downloaded, open its existing folder.



Run the remaining local commands from the project folder.



**2. Configure the local password**



Create a `.env` file containing:



```text

LOCAL_DB_PASSWORD=replace_with_your_local_password

```



Replace the example with a local development password. Keep `.env` out of Git.



**3. Build the application image**



```powershell

docker build -t support-ticket-app .

```



**4. Start the containers**



```powershell

docker compose up -d

```



**5. Create the database tables**



```powershell

docker compose exec web flask --app app init-db

```



Run this on the first setup or after deleting the database volume. It creates missing tables; it does not migrate existing table structures.



**6. Open and check the application**



Open http://localhost:5000.



Create a sample ticket, view it, and mark it as resolved.



**7. Troubleshoot if needed**



```powershell

docker compose ps

docker compose logs web

```



**AWS Infrastructure Updates**



This workflow updates the existing AWS infrastructure. It requires the project's AWS roles, S3 state storage, GitHub environment, and repository variables to be configured first.



This section is not a complete setup guide for a new AWS account.



| GitHub variable | Purpose |

|---|---|

| TF_VAR_application_task_count | Number of application tasks |

| TF_VAR_application_image_tag | Application image version |

| TF_VAR_allowed_browser_cidr | Allowed public IPv4 address followed by /32 |



**To update infrastructure:**



1\. Open the repository's Actions tab.

2\. Select "Terraform infrastructure."

3\. Choose "Run workflow" and select main.

4\. Start the workflow.

5\. Wait for the checks and planning stage.

6\. Review the proposed changes in the workflow summary.

7\. Approve the apply stage if the environment requires approval.

8\. Confirm that the apply stage succeeds.



The workflow saves the plan in S3 and verifies its checksum before applying it. Separate AWS roles are used for planning and applying changes.



Approval is enforced only if required reviewers are configured for the `terraform-apply` environment.



**Workflow:** [Terraform infrastructure](.github/workflows/infrastructure.yml)



**Stop the Local Application**



**From the project folder:**



```powershell

docker compose down

```



This removes the containers while keeping the database volume.



\### Delete Local Test Data



Only when you want to delete the local database data:



```powershell

docker compose down -v

```



This deletes stored local tickets. It does not delete AWS resources.



**AWS Cleanup**



These steps delete AWS infrastructure. Save any data and evidence you want to keep first.



**1. Avoid overlapping deployments**



Do not start deployment workflows during cleanup.



**2. Disable database deletion protection**



In `infrastructure/database.tf`, set:



```hcl

deletion_protection = false

```



Apply and verify this change through the infrastructure workflow before deletion. Editing the file alone does not change the existing database.



**3. Check the final snapshot name**



The configuration uses:



```hcl

final_snapshot_identifier = "ticket-postgres-final"

```



If that snapshot name already exists, choose a unique name and apply the configuration change before deletion.



**4. Open the infrastructure folder**



From the project folder:



```powershell

cd infrastructure

```



Authenticate to AWS using an identity authorized to remove the project resources. Supply the same Terraform variable values used for deployment.



**5. Initialize Terraform**



```powershell

terraform init

```



**6. Create and review the deletion plan**



```powershell

terraform plan -destroy -out=cleanup.tfplan

```



Confirm that the listed resources belong to this project.



**7. Apply the deletion plan**



Only when ready to delete the listed resources:



```powershell

terraform apply cleanup.tfplan

```



**8. Check remaining resources**



Check for:



\- Final and recovery-test snapshots.

\- The separate recovery-test database.

\- ECR images or repositories that could not be removed.

\- Manually created resources.

\- Terraform state and saved plans in S3.



Keep the state bucket until cleanup is complete and verified. State and plan files must remain private.



Retained snapshots and other remaining resources can continue to generate charges.



**Costs and Limitations**



The project uses AWS region us-east-2. Costs have not yet been measured.



Application hosting, the load balancer, database, storage, and other resources can generate charges.



Current limitations:



\- The database uses one Availability Zone without a standby in another zone.

\- Browser access uses HTTP and is restricted to the configured IP address.

\- Dashboards and automated alerts are not defined in Terraform.

\- The recovery check verified one expected ticket.

\- The AWS update instructions assume existing account and workflow setup.



**Lessons Learned**



\- Recovery includes verifying restored data, not only restoring a database.

\- Network rules control which components can communicate.

\- Deployment workflows can scan images and verify the deployed application version.

