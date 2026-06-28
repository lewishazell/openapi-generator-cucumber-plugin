# OpenAPI Generator Cucumber Plugin - development guide

## Overview

This plugin generates Cucumber step definitions for OpenAPI specifications, enabling BDD testing of REST APIs. It supports:

- **Languages**: TypeScript, Python, Java, Go, C#
- **Features**:
  - JSON Path chaining (`Given the "id" parameter is "$.id" from the previous response`)
  - Request/response validation
  - File uploads
  - Authentication (API keys, access tokens)

## Setup

### Prerequisites

- Java 11+
- Maven 3.6+
- Node.js (for TypeScript tests)
- Python 3.7+ (for Python tests)
- Go 1.16+ (for Go tests)
- .NET 6+ (for C# tests)

### Build the plugin

```bash
mvn clean package
```

This generates `target/openapi-generator-cucumber-plugin-1.0.0-SNAPSHOT.jar`.

## Running tests

### Execute all tests

```bash
cd tests
./test_codegen.sh
./test_auth.sh
```

### Update snapshots

If test output changes (e.g., after modifying step implementations), update snapshots:
```bash
cd tests
./update_snapshots.sh
```

### Test-specific commands

- **TypeScript**: `npm run build && npm test` (in `tests/out/`)
- **Python**: `pytest` (in `tests/out/`)
- **Java**: `mvn test` (in `tests/out/`)
- **Go**: `go test ./...` (in `tests/out/`)
- **C#**: `dotnet test` (in `tests/out/`)

## Adding new step implementations

### 1. Define the Step in Feature Files

Add the step to `tests/mocks/petstore/features/PetStore.prism.feature` (or other mock feature files). Example:

```gherkin
Given the "<parameter>" parameter is "<jsonPath>" from the previous response
```

### 2. Implement the step in mustache templates

Edit the language-specific template in `src/main/resources/<language>-cucumber/cucumber_steps.mustache`. Example for Java:

```java
@Given("the {string} parameter is {string} from the previous response")
public void givenTheParameterIsFromPreviousResponse(String parameter, String jsonPath) {
    if (previousResponse == null) {
        throw new IllegalStateException("No previous response exists.");
    }
    // ... implementation
}
```

### 3. Add dependencies (if needed)

Update the language-specific dependency file (e.g., `pom.mustache` for Java, `package.mustache` for TypeScript).

### 4. Test the implementation

1. Build the plugin (`mvn clean package`).
2. Run tests (`./tests/test_codegen.sh`).
3. Update snapshots if needed (`./tests/update_snapshots.sh`).

## Key directories

| Directory | Purpose |
|-----------|---------|
| `src/main/java` | Plugin code (Java). |
| `src/main/resources` | Mustache templates for code generation. |
| `tests/` | Test suite and mock OpenAPI specs. |
| `tests/mocks/` | Mock APIs and feature files. |
| `tests/snapshots/` | Expected test output (for comparison). |

## JSON path chaining

### How it works

1. **State management**: Previous responses are stored in `testContext` (Python), `scenarioContext` (Java/C#), or global variables (Go/TypeScript).
2. **Error handling**: Steps fail if:
   - No previous response exists.
   - Previous response is not JSON.
   - JSON Path query returns no results.
3. **Libraries**:
   - TypeScript: `jsonpath-plus`
   - Python: `jsonpath-ng`
   - Java: `com.jayway.jsonpath:json-path`
   - Go: `github.com/PaesslerAG/jsonpath`
   - C#: `JsonPath.Net`

### Example

```gherkin
Given there is an "addPet" request for the "DefaultApi"
And the "PetDetails" parameter has a JSON value of:
  """
  {"name": "Pickle", "tag": "cat"}
  """
When the request is sent
Then the response status should be 200

Given there is a "findPetById" request for the "DefaultApi"
And the "id" parameter is "$.id" from the previous response
When the request is sent
Then the response status should be 200
```

## Troubleshooting

### Common issues

1. **Snapshot mismatches**:
   - Run `./tests/update_snapshots.sh` to regenerate snapshots.
2. **Missing dependencies**:
   - Ensure all language-specific dependencies are installed (e.g., `npm install`, `pip install -r requirements.txt`).
3. **Prism mock API**:
   - Prism returns placeholder values (e.g., `"name":"string"`). Tests must account for this.

### Debugging tests

- **Java**: Run `mvn test -X` for debug logs.
- **Python**: Run `pytest -v` for verbose output.
- **TypeScript**: Run `npm test -- --verbose`.

## Releasing

1. Update the version in `pom.xml`.
2. Build the plugin (`mvn clean package`).
3. Deploy to Maven Central or a local repository.

## Contributing

1. Fork the repository.
2. Create a feature branch.
3. Implement changes and add tests.
4. Update snapshots if needed.
5. Submit a PR.