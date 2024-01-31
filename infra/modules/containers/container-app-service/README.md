# Container App Service

Container App Service

## Details

{{Add detailed information about the module}}

## Parameters

| Name                        | Type     | Required | Description                               |
| :-------------------------- | :------: | :------: | :---------------------------------------- |
| `location`                  | `string` | No       | Specifies the location for resources.     |
| `resourceTags`              | `object` | No       | Tags retrieved from parameter file.       |
| `serviceName`               | `string` | Yes      | Name of the service-                      |
| `serviceType`               | `string` | Yes      | Type of service.                          |
| `containerAppEnvironmentId` | `string` | Yes      | Id of container environment to deploy to. |

## Outputs

| Name | Type     | Description            |
| :--- | :------: | :--------------------- |
| `id` | `string` | The id of the service. |

## Examples

### Example 1

```bicep
```

### Example 2

```bicep
```