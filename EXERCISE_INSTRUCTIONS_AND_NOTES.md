# Automate Model Training with GitHub Actions - Exercise Guide

This folder (`C:\Users\Gaming pc\Desktop\AI300\GitHub_Actions`) contains the local repository files required for completing the **Automate model training with GitHub Actions** exercise. The sample repository (`mslearn-mlops`) has been cloned here, and all required code edits have already been pre-applied.

---

## 🚀 Overview of Changes Already Applied to Local Files

1. **Updated Job Definition (`src/job.yml`)**:
   - Replaced placeholder values for `training_data`.
   - Set `type: uri_file` and `path: azureml:diabetes-data@latest` so the job correctly references the dataset created by the setup script.

2. **Updated Workflow Definition (`.github/workflows/manual-trigger-job.yml`)**:
   - Added the `pull_request` trigger targeting the `main` branch alongside `workflow_dispatch`.
   - Added the final execution step: `az ml job create -f src/job.yml --stream --resource-group ${{ vars.AZURE_RESOURCE_GROUP }} --workspace-name ${{ vars.AZURE_WORKSPACE_NAME }}`.

---

## 🛠️ Step-by-Step Exercise Execution Guide

### Phase 1: Provision Azure Machine Learning Workspace
1. Open the [Azure Portal](https://portal.azure.com/) and launch **Cloud Shell** (Bash).
2. Run the lab setup script to create your Resource Group, Workspace, and Compute cluster:
   ```bash
   rm -r mslearn-mlops -f
   git clone https://github.com/MicrosoftLearning/mslearn-mlops.git mslearn-mlops
   cd mslearn-mlops/infra
   ./setup.sh
   ```
3. Once finished, verify in the Azure Portal that your resource group (`rg-ai300-...`) and workspace (`mlw-ai300-...`) are created.

### Phase 2: Create Your GitHub Repository & Configure Authentication
1. Go to [mslearn-mlops on GitHub](https://github.com/MicrosoftLearning/mslearn-mlops) and click **Use this template** > **Create a new repository**.
2. Name your repository (e.g., `mslearn-mlops`) and create it. Enable **GitHub Actions** under the Actions tab if prompted.
3. In Azure Cloud Shell, create a Service Principal for GitHub Actions (replace placeholders with your actual subscription ID and resource group name):
   ```bash
   az ad sp create-for-rbac --name "sp-mslearn-mlops-github" --role contributor \
       --scopes /subscriptions/<subscription-id>/resourceGroups/<your-resource-group-name> \
       --sdk-auth
   ```
4. Copy the JSON output.
5. In your GitHub repository:
   - Go to **Settings > Secrets and variables > Actions**.
   - Under **Secrets**, click **New repository secret**. Name: `AZURE_CREDENTIALS`, Value: paste the JSON output.
   - Under **Variables**, click **New repository variable**. Name: `AZURE_RESOURCE_GROUP`, Value: your exact resource group name.
   - Click **New repository variable** again. Name: `AZURE_WORKSPACE_NAME`, Value: your exact workspace name.

### Phase 3: Push Local Changes & Run Workflow Manually
To link this local folder (`C:\Users\Gaming pc\Desktop\AI300\GitHub_Actions`) to your new GitHub repository and trigger the training job:

1. Open PowerShell or Command Prompt in this folder and point the git remote to your new GitHub repository:
   ```powershell
   cd "C:\Users\Gaming pc\Desktop\AI300\GitHub_Actions"
   git remote set-url origin https://github.com/aishwaryshukla230895-sudo/mslearn-mlops.git
   ```
2. Commit and push the pre-applied exercise changes:
   ```powershell
   git add .
   git commit -m "Configure training job and GitHub Actions workflow"
   git push -u origin main
   ```
3. Go to the **Actions** tab in your GitHub repo, select **Manually trigger an Azure Machine Learning job**, and click **Run workflow**.
4. Check Azure Machine Learning studio -> **Jobs** to confirm the model training ran successfully!

### Phase 4: Test Pull Request Workflow & Branch Protection
1. In GitHub **Settings > Branches**, add a branch protection rule for `main` checking **Protect matching branches** and preventing direct pushes.
2. In your local terminal, create a feature branch:
   ```powershell
   git checkout -b feature/update-parameters
   ```
3. Modify a hyperparameter in `src/job.yml` (e.g., change `reg_rate: 0.01` to `0.02`).
4. Commit and push the branch:
   ```powershell
   git add .
   git commit -m "Adjust training parameter reg_rate"
   git push --set-upstream origin feature/update-parameters
   ```
5. Open a Pull Request on GitHub from `feature/update-parameters` to `main`. Watch the GitHub Actions workflow automatically trigger!
