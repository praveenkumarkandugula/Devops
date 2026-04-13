# Terraform Environments

This directory contains environment-specific Terraform configurations for Azure infrastructure management. It follows a modular approach where each environment (dev, prod) maintains its own settings while leveraging reusable modules.

## 📋 Directory Structure

```
environments/
├── dev/                     # Development environment configuration
│   ├── main.tf             # Core resource definitions (VNets, Resource Groups, Subnets)
│   ├── provider.tf         # Azure provider configuration and required versions
│   ├── variables.tf        # Input variables with default values
│   ├── terraform.tfvars    # Variable values specific to dev environment
│   ├── terraform.tfstate   # State file (tracks current infrastructure state)
│   └── apply_output.txt    # Output from last terraform apply execution
│
├── prod/                    # Production environment configuration
│   ├── main.tf             # Core resource definitions
│   ├── provider.tf         # Provider configuration
│   ├── variables.tf        # Input variables
│   └── terraform.tfvars    # Production-specific variable values
│
└── README.md               # This file
```

## 🔧 Configuration Overview

### Development Environment (`dev/`)

**Purpose:** Lower-cost environment for testing and development

**Key Features:**
- **Location:** East US region
- **VM Sizes:** Standard_B2s (Gen2-compatible, cost-optimized)
- **VNet CIDR:** 10.10.0.0/16
- **Subnets:**
  - App tier: 10.10.1.0/24
  - Database tier: 10.10.2.0/24
  - Management tier: 10.10.3.0/24
- **Resource Group:** `rg-network-dev`
- **VMs:** Linux (Ubuntu 22.04 LTS Gen2) and Windows Server 2022 (Gen2)
- **Tagging:** Automatically tagged as "Development" environment
- **State Backend:** Azure Storage Account `sttfstatedevpkc01` in remote backend

### Production Environment (`prod/`)

**Purpose:** Production-grade infrastructure with high availability considerations

**Key Features:**
- **Location:** East US region
- **VNet CIDR:** 10.20.0.0/16
- **Subnets:**
  - App tier: 10.20.1.0/24
  - Database tier: 10.20.2.0/24
  - Management tier: 10.20.3.0/24
- **Resource Group:** `rg-network-prod`
- **Tagging:** Automatically tagged as "Production" environment
- **Security:** Network Security Groups (NSGs) enabled for traffic control

## 📁 File Descriptions

### `main.tf`
Contains the primary resource definitions for each environment:
- **Resource Group:** Azure container for organizing resources
- **VNet Module:** Calls the reusable vnet module with environment-specific parameters
- **Configuration:** Network topology, subnet definitions, and security rules

### `provider.tf`
Defines the Terraform provider configuration and backend setup:
- **Provider:** Azure Resource Manager (azurerm)
- **Version:** ~> 3.0 (allows patch updates within version 3.x)
- **Features:** Empty block allows default feature behavior
- **Backend:** Azure Storage (remote state management)
  - Storage Account: `sttfstatedevpkc01`
  - Container: `tfstate`
  - Dev State Key: `env:dev.tfstate`
  - Resource Group: `rg-network-dev`
  - **Status:** Configured and ready for state migration

### `variables.tf`
Declares input variables used throughout the configuration:
- `location` - Azure region (default: eastus)
- `linux_vm_size` - Compute SKU for Linux VMs (default: Standard_B2s)
- `windows_vm_size` - Compute SKU for Windows VMs (default: Standard_B2s)
- `vm_admin_username` - Basic VM admin user
- `vm_admin_password` - Protected sensitive credential

### `terraform.tfvars`
Provides concrete values for variables:
- Environment-specific parameter assignments
- **NOTE:** Contains placeholder password - update before deploying

### `terraform.tfstate`
Terraform state file (managed automatically):
- Tracks the current state of deployed resources
- Enables Terraform to plan and apply changes
- **Never commit to version control** (included in .gitignore)

## 🏗️ How the Configuration Works

### Modular Architecture

Each environment references the **vnet module** located at `../../modules/vnet/`:

```
Environment Layer (dev/prod)
    ├── Defines resource groups
    ├── Sets security policies
    └── Calls reusable modules
            ↓
        VNet Module
            ├── Creates virtual networks
            ├── Manages subnets
            ├── Configures NSGs
            └── Handles network policies
```

### Configuration Flow

1. **Provider Configuration** → `provider.tf` sets up Azure connection
2. **Variables** → `variables.tf` & `terraform.tfvars` define inputs
3. **Main Resources** → `main.tf` creates resource groups and calls modules
4. **Module Processing** → Reusable vnet module creates networking resources
5. **State Management** → `terraform.tfstate` records deployed resources

## 🚀 Getting Started

### Prerequisites
- Terraform (v1.0+)
- Azure CLI authenticated and configured
- Appropriate Azure subscription access
- Understanding of CIDR notation for IP addressing

### Common Commands

#### Initialize Terraform (required before first use)
```bash
cd terraform/environments/dev
terraform init
```

#### Validate configuration syntax
```bash
terraform validate
```

#### Preview changes (before deployment)
```bash
terraform plan -out=tfplan
```

#### Apply configuration and deploy resources
```bash
terraform apply tfplan
```

#### View current infrastructure state
```bash
terraform show
```

#### Destroy resources (caution: affects deployed infrastructure)
```bash
terraform destroy
```

## 🔐 Security & Best Practices

### Credentials & Sensitive Data
- **Passwords:** Change `vm_admin_password` from default placeholder before deploying
- **State Files:** Stored in Azure Storage (encrypted), never committed to git
- **Backend:** Uses managed identity for secure Azure authentication
- **Secrets:** Never hardcode secrets - use Azure Key Vault for production

### Remote State Backend
- **Always use remote state** for team environments and production
- **Never commit local state files** - .gitignore prevents this
- **Backup state regularly** using `terraform state pull` for disaster recovery
- **Limit access** to storage account using Azure RBAC

### Environment Separation
- **Dev Environment:** Lower costs, experimental features acceptable
- **Prod Environment:** Stricter controls, higher resource standards
- **Isolation:** Each environment has separate resource groups and networking
- **State Isolation:** Dev and Prod share storage account but use separate state files

## 📝 Modifying Configurations

### To Change Environment Settings

1. **Update variable values:**
   ```bash
   # Edit the relevant environment's terraform.tfvars
   nano prod/terraform.tfvars
   ```

2. **Preview changes:**
   ```bash
   cd prod/
   terraform plan
   ```

3. **Apply changes:**
   ```bash
   terraform apply
   ```

### To Add New Subnets

Edit `main.tf` in the environment and add to the `subnets` map:

```hcl
subnets = {
  existing_subnet = { ... },
  new_subnet = {
    name              = "snet-new-prod-eastus"
    address_prefixes  = ["10.20.4.0/24"]
    service_endpoints = ["Microsoft.Storage"]
  }
}
```

### To Change Azure Region

Update the `location` variable in `terraform.tfvars`:

```hcl
location = "westus2"  # Change region here
```

## 📊 Resource Naming Convention

Resources follow Azure naming standards:

| Resource Type | Example | Pattern |
|---|---|---|
| Resource Group | `rg-network-dev` | `rg-[purpose]-[env]` |
| VNet | `vnet-dev-eastus` | `vnet-[env]-[region]` |
| Subnet | `snet-app-dev-eastus` | `snet-[tier]-[env]-[region]` |
| NSG | `nsg-dev-vnet-dev-eastus` | `nsg-[env]-[vnet]-[region]` |

## 🔄 Terraform State Management

### Remote State Backend (Azure Storage)

Your Terraform state is managed remotely in Azure Storage for team collaboration and safety:

**Storage Details:**
- **Account:** `sttfstatedevpkc01` (in `rg-network-dev` resource group)
- **Container:** `tfstate`
- **Dev State:** `env:dev.tfstate` (imported and ready)
- **Region:** East US

**Status:**
- ✅ Storage account created and imported
- ✅ Storage container created and imported
- ⏳ Backend migration ready (run `terraform init -migrate-state` after applying VMs)

**Benefits:**
- ✅ Team collaboration - multiple users can access same state
- ✅ Security - state encrypted at rest in Azure
- ✅ Backup & Recovery - Azure Storage handles redundancy
- ✅ No local conflicts - eliminates merge conflicts
- ✅ Audit trail - all changes logged in Azure

### State File Location
- **Remote:** Azure Storage Blob (`sttfstatedevpkc01/tfstate/`)
- **Local Cache:** `.terraform/terraform.tfstate` (temporary, don't commit)

### Protecting State
```bash
# View state without sensitive data
terraform show -no-color | grep -v password

# List all managed resources
terraform state list

# Inspect specific resource
terraform state show azurerm_resource_group.rg
```

## � Current Deployment Status (April 2026)

### ✅ Completed

**Infrastructure Created:**
- ✅ Resource Group (`rg-network-dev`) - imported
- ✅ Virtual Network (`vnet-dev-eastus`)
- ✅ 3 Subnets: app (10.10.1.0/24), db (10.10.2.0/24), management (10.10.3.0/24)
- ✅ Network Security Group (`nsg-dev-vnet-dev-eastus`) with 3 security rules
- ✅ Storage Account (`sttfstatedevpkc01`) for Terraform state
- ✅ Storage Container (`tfstate`) for remote state storage
- ✅ Network Interfaces for VMs

**Issues Resolved:**
- ✅ Fixed `for_each` loop in vnet module subnet-NSG associations (removed problematic `if contains()` condition)
- ✅ Fixed `for_each` loop in vnet module subnet-route table associations
- ✅ Fixed VM hypervisor generation mismatch by updating VM sizes to `Standard_B2s` (Gen2-compatible)
- ✅ Changed VM images to Gen2 (Ubuntu 22.04 LTS Gen2, Windows Server 2022 Gen2)
- ✅ Imported existing Resource Group into Terraform state
- ✅ Imported Storage Account and Container into Terraform state

### 🔄 In Progress / Pending

**Resources Being Created:**
- ⏳ Linux Virtual Machine (`vm-linux-dev-01`) - Ubuntu 22.04 LTS Gen2, Standard_B2s
- ⏳ Windows Virtual Machine (`vm-windows-dev-01`) - Windows Server 2022 Gen2, Standard_B2s

**Configuration Tasks:**
- ⏳ VM creation completion (typically 5-15 minutes)
- ⏳ Remote state backend migration via `terraform init -migrate-state`

### 📊 Resource Summary Table

| Component | Resource Name | Status | Details |
|---|---|---|---|
| **Compute** | vm-linux-dev-01 | ⏳ Creating | Ubuntu 22.04 LTS Gen2, Standard_B2s |
| | vm-windows-dev-01 | ⏳ Creating | Windows Server 2022 Gen2, Standard_B2s |
| **Networking** | vnet-dev-eastus | ✅ Created | CIDR: 10.10.0.0/16 |
| | snet-app-dev-eastus | ✅ Created | CIDR: 10.10.1.0/24 |
| | snet-db-dev-eastus | ✅ Created | CIDR: 10.10.2.0/24 |
| | snet-mgmt-dev-eastus | ✅ Created | CIDR: 10.10.3.0/24 |
| | nic-linux-dev-01 | ✅ Created | Connected to app subnet |
| | nic-windows-dev-01 | ✅ Created | Connected to app subnet |
| | nsg-dev-vnet-dev-eastus | ✅ Created | 3 inbound rules configured |
| **Storage** | sttfstatedevpkc01 | ✅ Created | Terraform state backend |
| | tfstate (container) | ✅ Created | State file location |
| **Management** | rg-network-dev | ✅ Imported | Resource Group |

### ⏭️ Next Steps

1. **Monitor VM creation:**
   ```bash
   cd terraform/environments/dev
   terraform state list  # Check for VM resources
   ```

2. **Once VMs are created, migrate state to backend:**
   ```bash
   terraform init -migrate-state
   ```
   When prompted, type `yes` to confirm the migration.

3. **Verify successful migration:**
   ```bash
   terraform plan  # Should show no changes
   terraform state list | grep vm  # VMs should appear
   ```

4. **Configure backend in provider.tf** (if not already done):
   ```hcl
   backend "azurerm" {
     resource_group_name  = "rg-network-dev"
     storage_account_name = "sttfstatedevpkc01"
     container_name       = "tfstate"
     key                  = "env:dev.tfstate"
   }
   ```

## �🛠️ Troubleshooting

### Connection Issues
```bash
# Verify Azure authentication
az account show

# Login if needed
az login
```

### State Lock Issues
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### Module Reference Errors
```bash
# Reinitialize modules
terraform init -upgrade
```

## 📚 Related Documentation

- **Modules:** See `../modules/vnet/` for VNet module documentation
- **Azure Provider:** [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- **Terraform State:** [Terraform State Documentation](https://www.terraform.io/language/state)

## ⚙️ Environment Comparison

| Aspect | Development | Production |
|--------|---|---|
| **Resource Group** | rg-network-dev | rg-network-prod |
| **VNet CIDR** | 10.10.0.0/16 | 10.20.0.0/16 |
| **VM Size** | Standard_A2_v2 | Standard_A2_v2* |
| **Tag Environment** | Development | Production |
| **Typical Use** | Testing, experimentation | Live workloads |
| **Cost Level** | Lower | Higher |

*Production VM sizes should be reviewed for workload requirements

## 🎯 Next Steps

1. **Initialize:** Run `terraform init` in your target environment
2. **Review:** Run `terraform plan` to see what will be created
3. **Deploy:** Run `terraform apply` to provision infrastructure
4. **Configure:** Adjust `terraform.tfvars` for your specific needs
5. **Monitor:** Track resources in Azure Portal or via CLI

## 📞 Support & Contribution

For issues, enhancements, or questions:
- Review Terraform error messages carefully
- Check Azure provider compatibility
- Validate CIDR blocks don't overlap
- Ensure sufficient Azure subscription permissions
