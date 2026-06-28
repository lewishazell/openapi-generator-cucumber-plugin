# Writing Cucumber scenarios for `openapi-generator-cucumber-plugin`

This guide explains how to write executable [Cucumber scenarios](https://cucumber.io/docs/gherkin/reference/) using the `openapi-generator-cucumber-plugin`. The plugin wires OpenAPI-defined operations into structured test steps, allowing you to write human-readable scenarios to verify real API client behavior.

## Plugin overview

This plugin enables you to describe HTTP API client scenarios in BDT-custom syntax, and automatically executes them using code generated via [openapi-generator](https://github.com/OpenAPITools/openapi-generator)

You define the intended behavior of the API client and the Cucumber steps will handle request construction, type coercion, response parsing and semantic comparisons.

## How Cucumber specs map to OpenAPI specs

| Cucumber Step Element           | Maps to OpenAPI Element                            |
|---------------------------------|----------------------------------------------------|
| API class (`PetApi`)            | The `tag` used in the OpenAPI operation definition |
| Operation ID (`findPetById`)    | The `operationId` in the OpenAPI operation object  |
| Parameters                      | Path, query, header, or body parameters            |
| Response status/content         | Defined responses for an operation                 |

### Example:

```yaml
paths:
  /pets/{id}:
    get:
      tags:
        - Pet
      operationId: findPetById
      parameters:
        - in: path
          name: id
          required: true
          schema:
            type: integer
```

In this case:

- The operation ID is `findPetById`
- The API class is `PetApi` (if tagged as "Pet") - or `DefaultApi` if untagged
- `id` is a required path parameter


### Naming normalization

Class names and operation IDs are normalized:

- API class names become **PascalCase**
- Operation IDs become **camelCase**

This ensures consistent naming across languages, as openapi-generator transforms identifiers.

## Supported steps

These are the officially supported Cucumber steps. Steps must be written in the correct sequence for each request.

Required step order:

1. Create the request
1. Set parameters (optional)
1. Send the request
1. Assert response

Multiple request cycles are supported per scenario - just repeat the pattern.

### 1. Create a request

```cucumber
Given there is a "findPetById" request for the "PetApi"
```

* `findPetById` is the `operationId`
* `PetApi` is the api class name, derved from `tags`

See your generated client code to confirm actual names.

### 2. Set parameter values

#### Simple value:

```cucumber
Given the "id" parameter has a value of "1"
```

#### JSON body value:

```cucumber
Given the "petDetails" parameter has a JSON value of:
  """
  { "name": "Pickle", "tag": "cat" }
  """
```

#### Multi-value array (e.g. query arrays:)

```cucumber
Given the "tags" parameter has the following values:
    | value |
    |-------|
    | cat   |
    | dog   |
```

### Type coercion

The plugin automatically coerces string values into the following types as defined by the schema:

- `int`, `float`, `double`, `boolean`
- `enum` values
- `UUID` / `GUID`

Type errors will be thrown if the string is in the incorrect format or coersion is not possible.

### JSON path chaining

You can chain JSON response data to request parameters using JSON Path. This allows you to extract values from a previous response and use them in subsequent requests.

```gherkin
Given the "id" parameter is "$.id" from the previous response
```

- `id` is the parameter name in the current request.
- `$.id` is the JSON Path expression to extract the `id` field from the previous response.

**Requirements:**
- The previous response must exist.
- The previous response must be JSON.
- The JSON Path must return a valid result.

**Error Cases:**
- No previous response exists.
- Previous response is not JSON.
- JSON Path query returns no results.

### 3. Send the Request

``` cucumber
When the request is sent
```

- Must come after setting parameters and before assertions.
- Internally, it executes the constructed request and stores the response for use in assertion steps.

### 4. Assert on the response

#### Status code:

``` cucumber
Then the response status should be 200
```

#### Response body:

```cucumber
Then the response content should be:
  """
  { "name": "Pickle", "tag": "cat", "id":1 }
  """
```

### Semantic JSON comparison

JSON content assertions use semantic equality, meaning:

- Property order doesn’t matter
- Whitespace is ignored
- Values must match in structure and content

#### Full-body matching:
```gherkin
Then the response content should be:
  """
  { "name": "Pickle", "tag": "cat", "id": 1 }
  """
```

#### Partial matching (subtree contains):
```gherkin
Then the response content should contain the subtree:
  """
  { "name": "Pickle", "tag": "cat" }
  """
```

The **subtree contains** assertion checks if the expected subtree exists within the actual response, ignoring extra fields. This is useful for:
- Ignoring volatile fields (e.g., IDs, timestamps).
- Validating nested structures without requiring a full match.
- Asserting array contents (e.g., `[{ "name": "Pickle" }]`).

Therefore, this assertion passes:

```cucumber
Then the response content should be:
  """
  { "name": "Pickle", "tag": "cat", "id":1 }
  """
```

even if the actual response is:

```json
{
  "id": 1,
  "tag": "cat",
  "name": "Pickle"
}
```

## Full example

```cucumber
Feature: PetStore API

Scenario: Successfully find a pet at the pet store

Given there is a "findPetById" request for the "PetApi"
And the "id" parameter has a value of "1"
When the request is sent
Then the response status should be 200
And the response content should be:
  """
  { "name": "Pickle", "tag": "cat", "id": 1 }
  """
```

## Notes & limitations

| Behavior                | Notes                                                                                                |
|-------------------------|------------------------------------------------------------------------------------------------------|
| Multiple requests       | You can issue multiple requests in a scenario. Just follow the create “params” sequence for each.    |
| Step ordering           | Steps must follow the defined sequence. For example, assertions before sending a request will fail.  |
| Partial JSON matching   | In addition to full-body JSON comparisons, you can assert that the response contains a **JSON subtree** (a subset of fields or nested structures). This is useful for ignoring volatile fields like IDs or timestamps. See the "Assert on the Response" section for details. |
| API class name fallback | If an OpenAPI operation has no tags, it defaults to `DefaultApi`.                                    |

## Tips

- Use `tags` in your OpenAPI spec to control grouping and generate better API class names
- Always verify the normalized names used in generated step implementation code if you are unsure what to use in the spec
- Table parameters are ideal for arrays and repeated query parameters

## Related resources

- [Cucumber Documentation](https://cucumber.io/docs/)
- [OpenAPI Specification](https://swagger.io/specification/)
- [OpenAPI Generator](https://github.com/OpenAPITools/openapi-generator)

