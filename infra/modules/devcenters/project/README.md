# Dev Box Project

Dev Box Project with Pool.

## Details

{{ Add detailed information about the module. }}

## Parameters

| Name                    | Type     | Required | Description                                       |
| :---------------------- | :------: | :------: | :------------------------------------------------ |
| `location`              | `string` | Yes      | Specifies the location for resources.             |
| `resourceTags`          | `object` | No       | Tags retrieved from parameter file.               |
| `devCenterId`           | `string` | Yes      | Id of the DevCenter to attach project to.         |
| `projectName`           | `string` | Yes      | Name of project.                                  |
| `devPoolName`           | `string` | Yes      | Name of DevBox pool.                              |
| `networkConnectionName` | `string` | Yes      | Name of network connection to attach to.          |
| `devBoxDefinitionName`  | `string` | Yes      | Name of DevBox definition.                        |
| `licenseType`           | `string` | No       | License Type of DevBox.                           |
| `localAdministrator`    | `string` | No       | Status of local admin account.                    |
| `deploymentTargetId`    | `string` | Yes      | SubscriptionId the environment will be mapped to. |

## Outputs

| Name                      | Type     | Description                                                |
| :------------------------ | :------: | :--------------------------------------------------------- |
| `devEnvironmentManagedId` | `string` | Id of the system-managed identity for the dev environment. |

## Examples

### Example 1

```bicep
```

### Example 2

```bicep
```