# Dev Center

Dev Center

## Details

{{ Add detailed information about the module. }}

## Parameters

| Name                    | Type     | Required | Description                                                                 |
| :---------------------- | :------: | :------: | :-------------------------------------------------------------------------- |
| `location`              | `string` | Yes      | Specifies the location for resources.                                       |
| `devCenterName`         | `string` | Yes      | Name of DevCenter                                                           |
| `networkConnectionId`   | `string` | Yes      | Network connection id for the network the Dev Center should be attached to. |
| `resourceTags`          | `object` | No       | Tags retrieved from parameter file.                                         |
| `image`                 | `string` | Yes      | DevBox definition image id.                                                 |
| `definitionName`        | `string` | No       | Name of DevBox definition.                                                  |
| `definitionSKU`         | `string` | No       | DevBox definition SKU.                                                      |
| `definitionStorageType` | `string` | No       | DevBox definition storage type.                                             |

## Outputs

| Name                       | Type     | Description                                          |
| :------------------------- | :------: | :--------------------------------------------------- |
| `devCenterId`              | `string` | Id of DevCenter.                                     |
| `devCenterAttachedNetwork` | `string` | Name of the attached network.                        |
| `devCenterManagedId`       | `string` | Id of the system-managed identity of the Dev Center. |

## Examples

### Example 1

```bicep
```

### Example 2

```bicep
```