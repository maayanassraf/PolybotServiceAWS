# The Polybot Service: AWS Project

## Background

This AWS project based on the [previous Docker project][PolybotServiceDocker], there I developed and deployed containerized service which detects objects in images sent through a Telegram chatbot. 
In addition, the service could effortlessly be launched on any machine using (almost) a single Docker compose command.

In this project, I'll deploy thr Polybot Service on AWS following best practices for a well-architected infrastructure.
By using variety of AWS resources, including EC2, VPC, IAM, S3, SQS, DynamoDB, ELB, ASG, CloudWatch, and more.

As an extension, I have used **Terraform** for building the entire infrastructure in the AWS. this project is 
currently deployable in 2 regions, and can be extended to more easily in small adjustments. 

## Flow Of Using The Service

1. Client sends images to the Telegram bot named **ImageProcessingBot**
2. The polybot microservice receives the message, downloads the image to s3.
3. The polybot microservice send a job to SQS.
4. The yolo5 microservice waiting for messages to retrieve from te SQS.
5. The yolo5 microservice processes the photo and detects objects in it.
6. The yolo5 microservice uploads the predicted image to s3.
7. The yolo5 microservice creates prediction summary an then stores it in DynamoDB.
8. Eventually, the yolo5 microservice initiates http post request to the polybot 
microservice for sending the result to the telegram-end-user.

## Infrastructure

- The AWS resources will be created in a VPC. The VPC has two public subnets in different AZs.
- The Polybot Service will deploy in EC2 instances. 
- For each object type, needed to have permission on some AWS services, it is done by attaching an **IAM role** with the required permissions.


## Provision the `polybot` microservice

![][botaws2]

- The Polybot microservice is running in a `micro` EC2 instance. The code is deployed under the `polybot/` folder.
- The app is running automatically as the EC2 instances are being started (in case the instance was stopped), **without any manual steps**.      
  I've made it automatically by running the docker container - with using the `--restart always` flag.
  
  Furthermore, docker is installed on the EC2's by [User Data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html).
- The service is highly available, By using an **Application Load Balancer (ALB)** that routes the traffic across the instances located in different AZs. 
  
  The ALB haves an **HTTPS** listener, for communicating with Telegram. To use HTTPS, I Have used **AWS Certificate Manager** (ACM)
to generate certificate and linked her to thr HTTPS listener.

- Access to The ALB done by accessing **Route 53 Record** that I created for the ALB.

- In the security group of the ALB, I configured an inbound role for the CIDR of Telegram servers only.
- My Telegram token stored in [AWS Secret Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html).
- The Polybot instances are tags for later use and for clearance.

## Provision the `yolo5` microservice

![][botaws3]

- The yolo5 microservice is running within a `medium` EC2 instance. The service files can be found under `yolo5/` folder. 
- The yolo5 microservice periodically consumes jobs from an **SQS queue**.
- The Yolo5 microservice is **auto-scaled**. For that, all the Yolo5 instances are part of an **Auto-scaling Group**. 
  I Created a Launch Template and Autoscaling Group, the service scaling up  based on **CPU utilization**, with a scaling policy triggered when the CPU utilization reaches **60%**.
- Similarly to the Polybot, the Yolo5 app is automatically up and running when an instance is being started as part of the ASG, without any manual steps.
- The yolo5 microservice is auto-scaled to launch new instances in the same AZs as the polybot microservice, as it also based on the same VPC and public subnets.
- The yolo5 microservice scalability has been tested by sending multiple images to the Telegram bot within a short timeframe, then
in the  **CloudWatch** console I observed the metrics related to CPU utilization for your Yolo5 instances, then an alarm was triggered and another yolo5 instance had created for handling the traffic.

**Polybot -> Yolo5 communication:** When the Polybot microservice receives a message from Telegram servers, it uploads the image to the S3 bucket. 
    Then the bot sends a "job" to an SQS queue.
    The job message contains information regarding the image to be processed, as well as the Telegram `chat_id`.
    The Yolo5 microservice acts as a consumer, consumes the jobs from the queue, downloads the image from S3, processes the image, and writes the results to a **DynamoDB table**.

**Yolo5 -> Polybot communication:** After writing the results to DynamoDB, the Yolo5 microservice then sends a `POST` HTTP request to the polybot microservice, to `/results?predictionId=<predictionId>`, while `<predictionId>` is the prediction ID of the job the yolo5 worker has just completed. 
  The request is done via the ALB domain address, but since this is an internal communication between the `yolo5` and the `polybot` microservices, HTTPS is not necessary here- I createD an HTTP listener in the ALB accordingly, and restrict incoming traffic for POST request only.
  The `/results` endpoint in the Polybot microservice then should retrieve the results from DynamoDB and sends them to the end-user Telegram chat by utilizing the `chat_id` value.

## CI/CD pipeline using GitHub Actions

I have implemented a CI/CD pipline in Github Actions for building infrastructure with terraform, for building new code versions to Polybot & Yolo5 microservices
and for deploying latest code versions to the infrastructure.

- The CI/CD for building in infrastructure with terraform is triggerd manually when choosing wanted region
for applying the terraform code in. This process is build from 2 workflows.

- The CI/CD for building new code versions is triggered automatically, by pushing code to branch main. 
Meaning, when you make code changes locally, then commit and push them, a new version of Docker image is being built and pushed to DockerHub. 
There are 2 separated GitHub Action workflows one for the Polybot microservice build and one for the Yolo5 microservice build. The implementation is under `.github/workflows/polybot-build.yaml` and `.github/workflows/yolo5-build.yaml` respectively.

- The CI/CD for deploying latest code versions is separated for polybot & yolo5 and triggerd manually. 
The deployment is done to exist infrastructure and triggered when choosing wanted region
for applying the terraform code in. This process is build from 2 workflows for each microservice.

### Implementation

### The Infrastructure Build

- This process is build from 2 workflows-
  1. Infra-provisioning-main.
  2. Infra-provisioning-region.
- The `Infra-provisioning-main` workflow is triggered manually, by choosing AWS Region for deploying thw project. 
In this workflow, the `Infra-provisioning-region` workflow is called with needed parameters (such as region, AWS Credentials...)
- After triggered, the `Infra-provisioning-region` workflow creating terraform workspace for the specific region and build the 
infrastructure according to the terraform files. 

#### The Polybot / Yolo5 Microservice Build

- There is separate build workflow for each microservice. 
- Matching workflow is triggered by pushing code to the `/polybot` or `/yolo5` sub-folders .

- The workflow builds and pushes new version of Docker images to matching DockerHub repo,
according to the microservice, using the DOCKER_REPO_USERNAME and DOCKER_REPO_PASSWORD secrets.
- Every workflow run, build image with 2 tags- 
  1. image version tag - for versioning docs & specific usage.
  2. latest tag (will be overwritten in new build) - for later deployment use.
- 
- In The Deployment phase, it gets the polybot EC2's Public IP's by their tags (the EC2 most be running for updating the new docker container on it),
it is using the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY secrets for accessing the AWS account.
- Afterward, it connects to the polybot EC2's by the IP which received as described above, and the EC2_SSH_PRIVATE_KEY provided as secret.
Then, it stops running container of polybot (if exists) and running new polybot container with the new previous built image.

#### The Polybot / Yolo5 Microservice Deployment

- There are separate deployments workflows for each microservice. 
- The deployment process for each microservice is build from 2 workflows-
  1. {MicroserviceName}-deployment-main.
  2. {MicroserviceName}-deployment-region.
- The `{MicroserviceName}-deployment-main` workflow is triggered manually, by choosing AWS Region for deploying the latest code version to. 
In this workflow, the `{MicroserviceName}-deployment-region` workflow is called with needed parameters (such as region, AWS Credentials...)
- After triggerd, the `{MicroserviceName}-deployment-region` workflow running the following steps-
  1. Gets the Microservice EC2's Public IP's by their tags (if instance has matching tag and not running, it will turn them on),
  it is using the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY secrets for accessing the AWS account.
  2. Creates new matching .env file adjusted to the region (includes all environment variables needed by the microservice containers),
  and use scp command for copy the file to the Microservice EC2's by the IP which received at step 1.
  3. Connects to the Microservice EC2's by the IP which received at step 1, and by the PRIVATE_KEY provided as secret in the workflow call 
  (the private key is supplied according to region).
  4. In each EC2, stops running Microservice container (if exists), deletes latest image exist locally and running 
  new microservice container with new latest version exist on DockerHub.


[DevOpsTheHardWay]: https://github.com/alonitac/DevOpsTheHardWay
[onboarding_tutorial]: https://github.com/alonitac/DevOpsTheHardWay/blob/main/tutorials/onboarding.md
[github_actions]: ../../actions

[PolybotServiceDocker]: https://github.com/maayanassraf/DockerProject
[botaws2]: https://alonitac.github.io/DevOpsTheHardWay/img/aws_project_botaws2.png
[botaws3]: https://alonitac.github.io/DevOpsTheHardWay/img/aws_project_botaws3.png
