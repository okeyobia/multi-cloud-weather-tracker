terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45"
    }
  }

  # Uncomment to use Azure Storage for remote state
  # backend "azurerm" {
  #   resource_group_name  = "terraform-state"
  #   storage_account_name = "tfstate"
  #   container_name       = "weather-tracker"
  #   key                  = "azure.tfstate"
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }

    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }

  skip_provider_registration = false
}

provider "azuread" {}

# Get current context
data "azurerm_client_config" "current" {}
