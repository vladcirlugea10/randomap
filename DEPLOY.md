# Workshop Guide: Deploying the "Randomap" Application

Welcome! In this guide, you will deploy a containerized web application to AWS using a fully automated CI/CD pipeline. By the end, you will have a live, public URL for your own version of the "Randomap" app, which will automatically update every time you push a code change.

---
## 1. Prerequisites: Setting Up Your Environment

This guide assumes you are using WSL (Windows Subsystem for Linux) and the Ubuntu distribution.

#### 1.1. Install Core Tools
First, install WSL and the necessary tools inside your Ubuntu terminal.
1.  **Install WSL:** Follow the official Microsoft guide to [install WSL](https://learn.microsoft.com/en-us/windows/wsl/install).
2.  **Update Ubuntu:**
    ```
    sudo apt-get update && sudo apt-get upgrade -y
    ```
3.  **Install `git`, `python`, and `pip`:**
    ```
    sudo apt-get install -y git python3-pip python3-venv
    ```

#### 1.2. Install Docker Engine (CLI on Linux)
We'll install the Docker engine directly inside WSL/Ubuntu.

1.  **Set up Docker's `apt` repository:**
    ```
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL [https://download.docker.com/linux/ubuntu/gpg](https://download.docker.com/linux/ubuntu/gpg) -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] [https://download.docker.com/linux/ubuntu](https://download.docker.com/linux/ubuntu) \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    ```
2.  **Install the Docker packages:**
    ```
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    ```
3.  **Manage Docker as a non-root user (Important!):** This allows you to run `docker` commands without `sudo`.
    ```
    sudo groupadd docker
    sudo usermod -aG docker $USER
    ```
    **You must close and reopen your WSL terminal for this change to take effect.** After reopening, verify it works by running `docker run hello-world`.

#### 1.3. Install AWS CLI
This is the command-line tool for interacting with your AWS account.

```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
#### 1.4. Install Terraform
This is the tool we'll use for Infrastructure as Code.

```
sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install terraform
```

#### 1.5. Required Accounts
**GitHub Account:** [Create one here](https://github.com/join).

---
## 2. Fork and Clone the Repository

To work on your own version of the application, you need to fork the main repository.

1.  Go to the instructor's repository URL: `https://github.com/nickolasdaniel/randomap`
2.  In the top-right corner, click the **Fork** button. This creates a personal copy of the repository under your GitHub account.
3.  On your forked repository's page, click the green **<> Code** button and copy the SSH clone URL.
4.  In your WSL terminal, clone **your forked repository**:
    ```
    git clone [paste-your-forked-repo-url-here]
    cd randomap # Or your repository's name
    ```

---
## 3. Configure Your AWS Credentials

Your instructor will provide you with a unique set of credentials. Use these to configure your AWS CLI so your computer can communicate with our shared AWS account.

1.  **Your instructor will give you:**
    * An **Access Key ID**
    * A **Secret Access Key**
2.  **In your terminal, run the configuration command:**
    ```
    aws configure
    AWS Access Key ID [None]: [PASTE THE ACCESS KEY ID YOU RECEIVED]
    AWS Secret Access Key [None]: [PASTE THE SECRET ACCESS KEY YOU RECEIVED]
    Default region name [None]: us-east-1
    Default output format [None]: json
    ```
3.  **Verify your identity:**
    ```
    aws sts get-caller-identity
    ```
    This should return the details of your assigned IAM user, confirming your CLI is working.

---

## 4. Configure GitHub Secrets

Now, provide your GitHub repository with the secrets it needs to connect to AWS.

1.  Go to your forked repository on GitHub.
2.  Navigate to **Settings** > **Secrets and variables** > **Actions**.
3.  Click **New repository secret** and add the following three secrets:
    * `AWS_OIDC_ROLE_ARN`: Paste the Role ARN of the GitHubActions-Randomap-Role that the instructor gave you.
    * `STUDENT_IDENTIFIER`: This must match what you use for Terraform e.g `student-niculea`.
    * `APP_AUTHOR`: Enter the name you want to see in the app's footer (e.g., `Nicu Crazy Style`).

---
## 5. Deploy the Infrastructure

We will now use Terraform to build our infrastructure. This is a three-step process because of a dependency between App Runner and ECR.

1.  **Run `terraform apply` (First Time):** This creates the ECR repository but will fail on the App Runner service because the repository is empty. **This failure is expected and okay.**
    ```
    terraform init
    terraform apply -var="student_identifier=[STUDENT_IDENTIFIER]" # Use the same identifier as your secret
    ```
    Type `yes` to approve. Wait for it to finish (it will end with an error).

2.  **Run the CI/CD Pipeline:** Now, push your code to GitHub to trigger the pipeline. This will build your Docker image and push it to the ECR repository that was just created.
    ```
    git add .
    git commit -m "Initial commit to trigger CI/CD"
    git push origin master
    ```
    Go to the **Actions** tab on your GitHub repository and wait for the workflow to succeed.

3.  **Run `terraform apply` (Second Time):** Now that an image exists in the repository, run the apply command again.
    ```
    terraform apply -var="student_identifier=[YOUR_IDENTIFIER]"
    ```
    This time, the process will complete successfully.

4.  **Get Your URL:** After the apply is complete, run the output command to get your live website link.
    ```
    terraform output app_url
    ```
    Visit the URL in your browser to see your live application!

---
## 6. The Victory Lap: Test a Change

1.  Make a small change to the title in the `templates/index.html` file.
2.  Commit and push the change:
    ```
    git add .
    git commit -m "feat: Update website title"
    git push origin master
    ```
3.  Watch your pipeline run in the **Actions** tab.
4.  Once it's finished, wait 1-2 minutes for App Runner to deploy, then **hard refresh** your browser (`Ctrl+Shift+R` or `Cmd+Shift+R`). Your changes will be live!

---
## 7. Cleanup

To avoid any potential costs, destroy all the infrastructure you created.

1.  Run the destroy command:
    ```
    terraform destroy -var="student_identifier=[YOUR_IDENTIFIER]"
    ```
2.  **Delete the ECR Repository:** Terraform cannot delete a repository that contains images.
    * Go to the **AWS Console** > **Elastic Container Registry (ECR)**.
    * Find your repository (`randomap-repo-...`), select it, and click **Delete**, following the instructions to force deletion.