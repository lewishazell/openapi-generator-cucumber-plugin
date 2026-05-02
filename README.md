# OpenAPI Generator Cucumber Plugin

![csharp tests](https://github.com/lewishazell/openapi-generator-cucumber-plugin/actions/workflows/csharp-tests.yml/badge.svg)
![python tests](https://github.com/lewishazell/openapi-generator-cucumber-plugin/actions/workflows/python-tests.yml/badge.svg)
![go tests](https://github.com/lewishazell/openapi-generator-cucumber-plugin/actions/workflows/go-tests.yml/badge.svg)
![java tests](https://github.com/lewishazell/openapi-generator-cucumber-plugin/actions/workflows/java-tests.yml/badge.svg)
![typescript-node tests](https://github.com/lewishazell/openapi-generator-cucumber-plugin/actions/workflows/typescript-node-tests.yml/badge.svg)
![license](https://img.shields.io/github/license/lewishazell/openapi-generator-cucumber-plugin?color=blue)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

## 💡 Project overview

**OpenAPI Generator Cucumber Plugin**  extends OpenAPI code generation by automatically generating Cucumber step implementations alongside your client libraries. This enables you to write [Gherkin scenarios](https://cucumber.io/docs/gherkin/reference) once and run them against client libraries in C#, Python, Go, Java, and TypeScript - allowing language-agnostic API testing without duplicating test logic.

## 🎯 Requirements

To use this plugin, you'll need **[OpenAPI Generator](https://openapi-generator.tech/docs/installation)** version **7.11.0**.

Ensure that both OpenAPI Generator is correctly set up before attempting to use this plugin.

## ⚙️ Installation & setup

Follow these steps to install and use the OpenAPI Generator Cucumber Plugin:

### 1. Install prerequisites

Before using the plugin, make sure both OpenAPI Generator is installed and available in your `PATH`.

- To install OpenAPI Generator, follow the instructions in [this guide](https://openapi-generator.tech/docs/installation).

### 2. Download the plugin JAR

You can download the latest version of the plugin from the [releases page](https://github.com/lewishazell/openapi-generator-cucumber-plugin/releases).

Alternatively, download the plugin with wget:

```
wget https://github.com/lewishazell/openapi-generator-cucumber-plugin/releases/download/v0.0.1-rc1/openapi-generator-cucumber-plugin-0.0.1-rc1.jar -O path/to/openapi-generator-cucumber-plugin-0.0.1-rc1.jar
```

### 3. Generate a client and step implementations

Now, generate a client using the OpenAPI Generator, specifying the Cucumber plugin to also generate step implementations. Here’s an example for generating a Python client:

```
openapi-generator-cli generate \
  --custom-generator path/to/openapi-generator-cucumber-plugin-0.0.1-rc1.jar \
  -g python-cucumber \
  -i path/to/your/openapi-spec.yaml \
  -p cucumberTargetHost=http://localhost:8080 \
  -o python-sdk/
```

- Replace `path/to/openapi-generator-cucumber-plugin-0.0.1-rc1.jar` with the location of the downloaded plugin JAR file.
- Replace `path/to/your/openapi-spec.yaml` with the path to your OpenAPI specification file.

This will generate a Python client along with the necessary step implementation files in the `python-sdk/` directory.

### 4. Copy your Cucumber features

Next, copy your Cucumber features into the generated output directory (e.g., `python-sdk/`).

```
cp -r features python-sdk
```

Ensure your feature files are in the correct directory, ready to be executed.

**NOTE:** For details on how to write your Cucumber features for use with this plugin, see the [scenario authoring guide](docs/scenario-authoring.md).

### 5. Run the tests

Navigate to the generated client folder and run your Cucumber tests.

```
cd python-sdk
pytest
```

The tests will be executed against the generated client, and you can see the results of the API tests in the output.

## 🚀 Usage tips

### Scenario authoring

See the [scenario authoring guide](docs/scenario-authoring.md) for details on how to write Gherkin scenarios for use with this plugin.

### Running specs in multiple languages:

After generating the client and step implementations for one language (e.g., Python), you can repeat the process for other languages (C#, Go, Java, TypeScript) by modifying the `-g` argument. The same set of scenarios will work for all clients.

The available generators are:

- `python-cucumber`
- `typescript-node-cucumber`
- `go-cucumber`
- `csharp-cucumber`
- `java-cucumber`

### Customizing the plugin:

If you need to customize how the step implementations are generated (e.g., adding custom logic or setting custom headers), you can [extend the templates](https://openapi-generator.tech/docs/customization/) provided by the plugin.

### Running tests on CI/CD:

You can integrate this plugin into your CI/CD pipeline to automatically validate the behavior of your API client against your OpenAPI specification whenever you generate a new client.

The steps are implemented as integration tests and can either run against an API mock such as [MockServer](https://www.mock-server.com/) or a real instance of your API. You could also use both of these methods, with quick validation from mocks in a PR gate and accuracy from an end-to-end run before release.

## 📜 License

This project is licensed under the [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0.html).
