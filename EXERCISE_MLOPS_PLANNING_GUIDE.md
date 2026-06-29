# Plan and Prepare an MLOps Solution with Azure Machine Learning - Exercise Guide

This folder (`C:\Users\Gaming pc\Desktop\AI300\MLOps_Environment_Planning`) contains the complete local workspace and designed bash scripts for the **Plan and prepare an MLOps solution with Azure Machine Learning** exercise.

---

## 🏛️ Target MLOps Architecture

In a mature machine learning lifecycle, isolation and sharing must be balanced carefully:
1. **Development Environment (`dev`)**:
   - Used by data scientists for ad-hoc experimentation and interactive model building.
   - Resource Group: `rg-ai300-dev-<suffix>`
   - Workspace: `mlw-ai300-dev-<suffix>`
   - Data Asset: `diabetes-dev-folder` pointing to sample data (`data/diabetes-data`).
2. **Production Environment (`prod`)**:
   - Used for automated training pipelines and live model deployment.
   - Resource Group: `rg-ai300-prod-<suffix>`
   - Workspace: `mlw-ai300-prod-<suffix>`
   - Data Asset: `diabetes-prod-folder` pointing to production datasets (`production/data`). **Production data is strictly isolated from development.**
3. **Shared Model Registry**:
   - A central repository accessible by both `dev` and `prod` workspaces to publish, promote, and share curated models, environments, and components.
   - Resource Group: `rg-ai300-reg-<suffix>`
   - Registry: `mlr-ai300-shared-<suffix>`

---

## 📜 Scripts Created & Reviewed

We have created two newly designed scripts inside `infra/` translating this architecture into concrete Azure CLI operations:

### 1. `infra/setup-prod-design.sh`
- A design script that sets up all three isolated resource groups simultaneously.
- Demonstrates how dynamic variables inject values into `registry.yml` using `sed`:
  ```bash
  sed -e "s|REGISTRY_NAME_PLACEHOLDER|$REGISTRY_NAME|g" \
      -e "s|PRIMARY_REGION_PLACEHOLDER|$RANDOM_REGION|g" \
      registry.yml > registry.generated.yml
  ```
- *File reference*: [setup-prod-design.sh](file:///C:/Users/Gaming%20pc/Desktop/AI300/MLOps_Environment_Planning/infra/setup-prod-design.sh)

### 2. `infra/setup-multi-env.sh`
- An automated entry point script designed for CI/CD tools (like GitHub Actions or Azure DevOps).
- Accepts a command-line argument (`dev` or `prod`) and dynamically branches variable assignment:
  ```bash
  ENVIRONMENT=${1:-dev}
  if [ "$ENVIRONMENT" = "prod" ]; then ...
  ```
- Ensures the shared model registry is provisioned while creating only the specific target environment requested.
- *File reference*: [setup-multi-env.sh](file:///C:/Users/Gaming%20pc/Desktop/AI300/MLOps_Environment_Planning/infra/setup-multi-env.sh)

---

## 🛠️ Step-by-Step Exercise Walkthrough

As noted in the exercise prompt:
> **[!IMPORTANT]** *For this lab, you don’t need to run the new commands that create extra resource groups and workspaces. Focus on understanding how you would structure the script so that dev and prod resources are clearly separated and production data stays out of the development environment.*

### If You Want to Test Running the Scripts in Azure Cloud Shell (Optional):
1. Open [Azure Portal Cloud Shell](https://portal.azure.com/) (Bash).
2. Clone or navigate to your repo and enter the `infra` folder:
   ```bash
   cd mslearn-mlops/infra
   ```
3. Make the designed scripts executable:
   ```bash
   chmod +x setup-prod-design.sh setup-multi-env.sh
   ```
4. Test multi-environment provisioning:
   ```bash
   # Provision development environment
   ./setup-multi-env.sh dev
   ```

---

## 🧹 Resource Cleanup

Remember that any active compute clusters or Azure ML workspaces will incur costs. To delete everything created during this planning session:
In Azure Cloud Shell or terminal:
```bash
# List and delete all lab resource groups starting with rg-ai300
for rg in $(az group list --query "[?starts_with(name, 'rg-ai300')].name" -o tsv); do
    echo "Deleting resource group: $rg..."
    az group delete --name $rg --yes --no-wait
done
```
