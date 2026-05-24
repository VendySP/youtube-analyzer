<p align="center">
  <img src="https://github.com/VendySP/all_markdown_assets/blob/main/youtube-analyzer_assets/logo.png" alt="Logo" />
</p>
![GitHub last commit](https://img.shields.io/github/last-commit/VendySP/youtube-analyzer)

An automated, serverless AWS cloud pipeline that allows users to instantly analyze and summarize YouTube video sentiment based on top comments, build entirely using Terraform. This project was built for educational purposes and was tested manually in the AWS Console before being implemented in Terraform.


## Technologies
- AWS
- Terraform
- Python
- HTML


## Key Features
- **State Locking**: Uses native S3 state locking to prevent multiple peoples from modifying the infrastructure at the same time.
- **Fully Serverless**: Leverages fully serverless AWS services, ensuring high scalability with near-zero idle operating costs.
- **Link Validation**: Automatically detects if a pasted YouTube link is valid before processing.
- **Adjustable Analysis Depth**: Easily change the number of comments to analyze just by tweaking an environment variable in the Lambda function.
- **Smart Translation**: Automatically detects non-English comments and translates them using Amazon Translate.
- **Sentiment Analysis**: Categorize granular comment sentiment (Positive, Negative, Neutral) using Amazon Comprehend.
- **AI Conclusion**: Generate a summary based of the top comments using Amazon Bedrock.


## Architecture Diagram
<p align="center">
  <img src="https://github.com/VendySP/all_markdown_assets/blob/main/youtube-analyzer_assets/architecture_diagram.png" alt="Architecture Diagram" />
</p>


## Running the Project

### Prerequisites
- Install and configure **AWS CLI** (Administrator permissions recommended).
- Install **Terraform**.


### Steps
1. Clone the repository.
2. Rename the `example.tfvars` file to `terraform.tfvars` 
3. Update the values inside the `terraform.tfvars` file. 
4. Deploy the **backend_bootstrap** (which provides the remote state bucket and state locking capabilities).
    ```bash
   cd terraform_code/backend_bootstrap
   terraform init
   terraform apply --auto-approve
    ```

5. Deploy the core **application** infrastructure.
    ```bash
   cd ../application
   terraform init
   terraform apply --auto-approve
    ```

6. Once the application deployment completes, both the API Gateway and S3 Website URL will be printed out as outputs in your terminal.
7. Open `src/index.html` and replace the value of the **API_ENDPOINT** variable with your newly created API Gateway URL.
8. Re-apply the application infrastructure to push your updated HTML file to the static website.
    ```
    terraform apply --auto-approve
    ```

9. Open the provided S3 Website URL in the browser. The application is now ready.

### Notes:
- **S3 Bucket Names:** May need to adjust the name of the S3 bucket. Names can only contain lowercase letters, numbers, and hyphens(-).
- **Endpoint Path:** When updating the `API_ENDPOINT`, make sure **not** to remove or overwrite the `/analyze` path.


## Preview:
![preview](https://github.com/VendySP/all_markdown_assets/blob/main/youtube-analyzer_assets/preview.gif)

