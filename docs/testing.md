# How the plugin's test suites work

`tests/test_codegen.sh` and `tests/test_auth.sh` verify the plugin **end to end**: they generate a real client with the Cucumber step definitions for every supported language, run the generated test suite against a local mock API, and compare the Cucumber report it produces against a committed snapshot.

Nothing about the generated project's exit code is asserted. The artifact under test is the **report**: which scenarios ran, which steps passed/failed/were skipped, and what they matched. This is what allows scenarios that are *supposed* to fail to be part of a passing test suite (see [Expected failures](#expected-failures)).

## Summary

| Script | Tests | What it covers |
| --- | --- | --- |
| `tests/test_codegen.sh` | 6 | All PetStore steps: CRUD, query arrays, JSON bodies, file upload, full/subtree JSON assertions, JSON Path chaining |
| `tests/test_auth.sh` | 10 | Bearer token and API key authentication against a protected endpoint (5 languages × 2 schemes) |

Both suites cover the same five languages: **C#, Go, Java (Gradle and Maven), Python, TypeScript (Node)**.

## How a test works

Each test function follows the same pipeline:

1. **Build the plugin** – `oneTimeSetUp` runs `mvn clean package` in the repository root and derives the jar path from the Maven project version. Pass `--jar-file` to skip this and test an existing jar instead.
2. **Generate a client** – `openapi-generator-cli --custom-generator <jar>` generates the language's `*-cucumber` client into `tests/out/`, with `-p cucumberTargetHost=...` baking in the mock server URL.
3. **Copy the features** – the `.feature` files (and any fixtures such as `photo.jpg`) are copied into the generated project so its runner picks them up.
4. **Run the generated suite** – the language's test runner compiles and executes the generated project. Its exit code is intentionally ignored.
5. **Capture the report** – the Cucumber JSON report is piped through `scrubCucumberReport` (normalisation) into `verifyJson`, which writes a `.received.json` file and diffs it against the `.verified.json` snapshot with [`jd`](https://github.com/josephburnett/jd).

| Test function | Generator | Runner command | Report source |
| --- | --- | --- | --- |
| `testCSharpCodegen` | `csharp-cucumber` | `dotnet build` + `dotnet test --no-build` | `reqnroll_report.ndjson` (Reqnroll messages) converted by `cucumber-json-formatter` |
| `testGoCodegen` | `go-cucumber` | `go get -u -v all && go test ./... -godog.format=cucumber:report.json` | `out/test/report.json` |
| `testJavaCodegenWithGradle` | `java-cucumber` | `gradle test` | `out/build/reports/cucumber-report.json` |
| `testJavaCodegenWithMaven` | `java-cucumber` | `mvn test` | `out/target/cucumber-report.json` |
| `testPythonCodegen` | `python-cucumber` | `pip install ... && pytest --cucumber-json cucumber-report.json` | `out/cucumber-report.json` |
| `testTypeScriptNodeCodegen` | `typescript-node-cucumber` | `npm install && npm run build && npx cucumber-js --format json:...` | `out/cucumber-report.json` |

The auth suite uses the same pipeline with the Earth spec; the only difference is the credentials passed to the generated test run via environment variables:

| Test function | Credentials |
| --- | --- |
| `test<Lang>AccessTokenAuth` | `cucumber_access_token=valid-token` |
| `test<Lang>ApiKeyAuth` | `cucumber_api_key=valid-api-key` + `cucumber_security_scheme=...` |

`cucumber_security_scheme` selects which declared API key scheme to use. The tests pass `ApiKeyAuth` (the scheme name) for Go, Java, Python and TypeScript, and `x-api-key` (the header name) for C# — the C# steps accept either form. The generated steps also support `cucumber_api_key_prefix` and `cucumber_target_host` at runtime (`cucumber_target_host` overrides the host baked in at generation time).

## Mock APIs

### PetStore — Prism on port 4010

- Spec: `tests/mocks/petstore/petstore-extended.yaml`, served with [`prism mock`](https://github.com/stoplightio/prism).
- Prism replies with spec examples, so responses contain placeholder values (e.g. `"name":"string"`, `id: -9007199254740991`). These are baked into the feature expectations.
- Feature: `tests/mocks/petstore/features/PetStore.prism.feature` — 12 scenarios covering creation/deletion/lookup, filtered list queries, a multipart file upload, JSON body parameters, exact and subtree response matching, and JSON Path chaining between requests.
- `tests/mocks/petstore/files/photo.jpg` is copied into each generated project before its tests run, for the upload scenario.
- A `docker-compose.yaml` is also provided if you prefer to run Prism in Docker.

### Earth — Express app on port 5000

- Spec: `tests/mocks/earth/openapi.yaml` — a single secured endpoint offering **either** `BearerAuth` or `ApiKeyAuth` (`x-api-key` header).
- Server: `tests/mocks/earth/app.js` accepts `Authorization: Bearer valid-token` **or** `x-api-key: valid-api-key`, and returns `401` otherwise. `npm install` runs once per suite for the single `express` dependency.
- Feature: `tests/mocks/earth/features/Earth.feature` — one scenario requesting `/the-meaning-of-life`.

Both mock servers are started once per suite in `oneTimeSetUp` and killed in `oneTimeTearDown`. Keep ports **4010** and **5000** free.

## The shUnit2 harness

Both scripts are [shUnit2](https://github.com/kward/shunit2) suites (sourced from `/usr/share/shunit2/shunit2`). Any shell function named `test*` is discovered and run as a test.

- `oneTimeSetUp` / `oneTimeTearDown` run once per suite: build the jar, start the mock server / kill it afterwards.
- `setUp` / `tearDown` run per test: create and remove `tests/out/`, so each test generates into a clean directory.
- `fail "message"` marks the current test as failed. shUnit2 exits `0` only if every test passed, which is what CI relies on.
- Output ends with `Ran N tests.` and `OK` (or `FAILED`, with the failing test names). For a filtered run, tests that are skipped announce `Skipping <Test> (filtered by FILTER=...)` and still count as passed.

Both scripts share three helpers:

- `filter "$FUNCNAME"` – skips a test unless its name matches `FILTER` (case-insensitive substring). `FILTER` can be set with `--filter` or as an environment variable; CI uses the environment variable.
- `scrubCucumberReport` – a `jq` filter that deletes volatile fields before comparison: scenario `start_timestamp`, every step's `result.duration` and `result.error_message`, and `after` hook durations. If a mismatch survives this, it is structural (scenario/step names and order, statuses, `match.location`, doc strings, feature URIs and line numbers).
- `verifyJson` – pipes the report through `scrubCucumberReport`, tees it to `snapshots/<TestFunction>.received.json`, and diffs it against `snapshots/<TestFunction>.verified.json` with `jd`. It derives the snapshot name from `${FUNCNAME[1]}`, so **the snapshot file must be named exactly after the test function**.

Note that assertions only happen at snapshot comparison time. A compilation error, network failure or assertion failure inside the generated project does not fail the shell test directly — it fails only if it changes the report (e.g. no report is produced, or step statuses change).

## Expected failures

The PetStore feature deliberately contains two scenarios that **must fail**, to prove the generated assertions actually reject incorrect responses ("testing the tester"):

- *Successfully find a pet at the pet store with an incorrect response status* — asserts `201` where the mock returns `200`.
- *Successfully find a pet at the pet store with an incorrect response content* — asserts a JSON body the mock does not return.

Because of this, **every `test*Codegen` runs a generated suite that exits non-zero**. The scripts never check the generated runner's exit code (no `|| fail` on `dotnet test`, `go test`, `mvn test`, etc.) — they only compare the resulting reports. When a step fails, the remaining steps in that scenario are normally recorded as `skipped`; Python's pytest-bdd instead reports the following assertion as failed as well, which is why the Python snapshot has three failed steps across two failed scenarios.

One more failure is currently expected:

- *`testPythonApiKeyAuth`* — the scenario fails because the generated Python fixture returns before attaching the API key (`configuration.api_key[...]` is never reached), so the mock responds `401`. This is a known gap in the Python step template, and the failure is encoded in `testPythonApiKeyAuth.verified.json`. The suite passes as long as the behaviour stays the same; fixing the template will require re-baselining that snapshot.

Expected failed scenarios per snapshot:

| Test | Scenarios | Failed scenarios |
| --- | --- | --- |
| `testCSharpCodegen` | 12 | 2 |
| `testGoCodegen` | 12 | 2 |
| `testJavaCodegenWithGradle` | 12 | 2 |
| `testJavaCodegenWithMaven` | 12 | 2 |
| `testPythonCodegen` | 12 | 2 (3 failed steps) |
| `testTypeScriptNodeCodegen` | 12 | 2 |
| All auth tests except `testPythonApiKeyAuth` | 1 | 0 |
| `testPythonApiKeyAuth` | 1 | 1 (request fails with 401; 3 failed steps) |

> The generated projects also contain generator-emitted unit/API tests, which may pass, fail, or be skipped. They are not part of the report comparison — only the Cucumber scenarios are.

## Snapshots

- `tests/snapshots/<TestFunction>.verified.json` — committed baseline.
- `tests/snapshots/<TestFunction>.received.json` — written by every run, ignored by git (via `tests/snapshots/*.received.*`).

`jd` compares JSON structurally (object key order does not matter), but everything left after scrubbing still matches literally. This means innocuous refactors can change snapshots:

- Renaming a generated step method or changing its signature changes `match.location` (e.g. `Earth.Test.Earth.Test.StepDefinitions.WhenTheRequestIsSent()`).
- Moving steps or editing feature files changes line numbers and step order.
- Changing a scenario's `Then` assertions changes step texts/statuses.

Only update snapshots when the change is intended. Inspect the difference first (run the suite and review the `.received.json` against the `.verified.json`), then:

```bash
cd tests
./update_snapshots.sh
```

`update_snapshots.sh` copies every `.received.json` over its `.verified.json`. Always review the resulting diff before committing.

## Running the tests

Prerequisites (versions as used in CI):

| Tool | Used for | CI version |
| --- | --- | --- |
| Java + Maven | Building the plugin, Maven Java tests | Java 24, Maven 3.6+ |
| [Gradle](https://gradle.org/) | Java Gradle tests | 8.14 |
| [.NET SDK](https://dotnet.microsoft.com/) | C# tests | 10.0.x |
| [Go](https://go.dev/) | Go tests | ^1.24 |
| [Python](https://www.python.org/) + pip | Python tests | 3.14 (3.13 for releases) |
| [Node.js](https://nodejs.org/) | TypeScript tests, mock tooling | 24.x |
| [`@stoplight/prism-cli`](https://github.com/stoplightio/prism) | PetStore mock | 5.14.2 |
| [`@openapitools/openapi-generator-cli`](https://github.com/OpenAPITools/openapi-generator-cli) | Code generation | 2.22.0 (generator 7.26.0, pinned in `tests/openapitools.json`) |
| [`cucumber-json-formatter`](https://github.com/cucumber/json-formatter) | Converting the C# Reqnroll report | v19.0.0 |
| [`jd`](https://github.com/josephburnett/jd) | Snapshot diffing | v2.5.0 |
| `jq` | Report normalisation | any recent |
| [shUnit2](https://github.com/kward/shunit2) | Test harness | apt package (`sudo apt install shunit2`) |

Run from the `tests/` directory — the scripts use relative paths and build the plugin in the parent directory:

```bash
cd tests

# Run a whole suite
./test_codegen.sh
./test_auth.sh

# Run a subset (case-insensitive substring match on the test function name)
./test_codegen.sh --filter CSharp
./test_auth.sh --filter Java
FILTER=CSharp ./test_codegen.sh   # same, via environment variable (used by CI)

# Test a prebuilt jar instead of rebuilding the plugin
./test_codegen.sh --jar-file ../target/openapi-generator-cucumber-plugin-1.0.0-SNAPSHOT.jar

# Update snapshots after an intentional change
./update_snapshots.sh
```

Notes:

- A filtered run still executes `oneTimeSetUp`, so it builds the plugin (unless `--jar-file` is given) and starts the mock server. A filter that matches nothing yields a suite where every test is skipped — and still reports `OK`, so double-check the filter output.
- Expect each first run to be slow: Maven builds the plugin, `openapi-generator-cli` downloads the pinned generator, and Go/npm/pip fetch dependencies.
- The release workflow runs both suites with `--jar-file "../$JAR_PATH"` to verify the exact artifact being released.
- CI runs one workflow per language (`.github/workflows/<lang>-tests.yml`), each setting `FILTER=test<Lang>*` and running both scripts.

## Troubleshooting

| Symptom | Likely cause / fix |
| --- | --- |
| `Connection refused` in a generated run | Mock server crashed or was killed (e.g. a stale process, or Prism failing to bind). Check processes on ports 4010 (PetStore) and 5000 (Earth), ensure they are free, and re-run. |
| `jq` / `jd` / `cucumber-json-formatter`: command not found | Install the missing tools (see prerequisites). |
| Snapshot mismatch (`verifyJson` fails) | Diff `snapshots/<Test>.received.json` against `.verified.json`; the change is either a regression or an intentional behaviour change (which needs `./update_snapshots.sh`). |
| A single test fails while others pass | Re-run it alone with `--filter <TestName>` for focused output; `tearDown` still runs, so the suite is repeatable. |
| All tests "skipped" | Your `--filter`/`FILTER` did not match any test function name. |
| Platform-specific failures (crlf, file paths, shUnit2 location) | The suites assume a Unix-like environment with a distro-installed shUnit2 (CI runs on `ubuntu-24.04`). |

## Adding a new test

1. Add a `test<Name>()` function to the relevant script, following the existing structure (`filter "$FUNCNAME" || return 0`, then generate/run/`verifyJson`).
2. Name the matching snapshot `snapshots/test<Name>.verified.json` — `verifyJson` resolves it from the function name.
3. Run the suite; a missing snapshot fails the comparison.
4. Review the generated `.received.json` and promote it with `./update_snapshots.sh` once it represents the desired behaviour.

## Related files

| Path | Purpose |
| --- | --- |
| `tests/test_codegen.sh` | Code generation suite (all languages) |
| `tests/test_auth.sh` | Authentication suite (all languages) |
| `tests/update_snapshots.sh` | Promotes `.received.json` snapshots to `.verified.json` |
| `tests/mocks/petstore/` | Prism spec, feature files and upload fixture |
| `tests/mocks/earth/` | Express mock, spec and feature file |
| `tests/snapshots/` | Committed `.verified.json` baselines |
| `tests/openapitools.json` | Pins the OpenAPI Generator CLI version used by the tests |
| `.github/workflows/*-tests.yml` | Per-language CI runs of both suites |
