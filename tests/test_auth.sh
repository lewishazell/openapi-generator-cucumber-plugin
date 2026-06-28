#!/bin/bash

while [[ $# -gt 0 ]]; do
  case "$1" in
    --jar-file)
      JAR_FILE="$2"
      shift 2
      ;;
    --filter)
      FILTER="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 [--jar-file path/to/jar] [--filter testname]"
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

oneTimeSetUp() {
    if [ "$JAR_FILE" = "" ]; then
        (cd .. && mvn clean package) || fail "Codegen plugin build failed"
        local version=$(cd .. && mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
        JAR_FILE="../target/openapi-generator-cucumber-plugin-$version.jar"
    fi

    if [ ! -f "$JAR_FILE" ]; then
        echo "Error: JAR file not found at $JAR_FILE"
        exit 1
    fi

    echo "Using JAR: $JAR_FILE"

    (cd mocks/earth && npm install)
    
    node mocks/earth/app.js &>/dev/null &
    EARTH_PID=$!
}

setUp() {
    mkdir -p out
}

testCSharpAccessTokenAuth() {
    filter "$FUNCNAME" || return 0

    local testdir="out/src/Earth.Test"
    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g csharp-cucumber --package-name Earth -i mocks/earth/openapi.yaml -o out -p cucumberTargetHost=http://localhost:5000
    cp -r mocks/earth/features/ "$testdir/Features"

    (cd out && cucumber_access_token="valid-token" dotnet test)

    cat $testdir/bin/Debug/*/reqnroll_report.ndjson | cucumber-json-formatter | scrubCucumberReport | verifyJson || fail "Received output differed from verified snapshot"
}

testCSharpApiKeyAuth() {
    filter "$FUNCNAME" || return 0

    local testdir="out/src/Earth.Test"
    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g csharp-cucumber --package-name Earth -i mocks/earth/openapi.yaml -o out -p cucumberTargetHost=http://localhost:5000
    cp -r mocks/earth/features/ "$testdir/Features"
    
    (cd out && cucumber_api_key="valid-api-key" cucumber_security_scheme="x-api-key" dotnet test)

    cat $testdir/bin/Debug/*/reqnroll_report.ndjson | cucumber-json-formatter | scrubCucumberReport | verifyJson || fail "Received output differed from verified snapshot"
}

testGoAccessTokenAuth() {
    filter "$FUNCNAME" || return 0

    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g go-cucumber --package-name earth -i mocks/earth/openapi.yaml -o out -p cucumberTargetHost=http://localhost:5000
    cp -r mocks/earth/features/ out/test/features
    
    (cd out && go get -u -v all && cucumber_access_token="valid-token" go test ./... -godog.format=cucumber:report.json)
    
    cat out/test/report.json | scrubCucumberReport | verifyJson || fail "Received output differed from verified snapshot"
}

testGoApiKeyAuth() {
    filter "$FUNCNAME" || return 0

    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g go-cucumber --package-name earth -i mocks/earth/openapi.yaml -o out -p cucumberTargetHost=http://localhost:5000
    cp -r mocks/earth/features/ out/test/features
    
    (cd out && go get -u -v all && cucumber_api_key="valid-api-key" cucumber_security_scheme="ApiKeyAuth" go test ./... -godog.format=cucumber:report.json)
    
    cat out/test/report.json | scrubCucumberReport | verifyJson || fail "Received output differed from verified snapshot"
}

testJavaAccessTokenAuth() {
    filter "$FUNCNAME" || return 0

    local resourcesdir="out/src/test/resources/org/openapitools/client"
    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g java-cucumber --package-name Earth -i mocks/earth/openapi.yaml -o out -p cucumberTargetHost=http://localhost:5000
    mkdir -p $resourcesdir
    cp -r mocks/earth/features/* $resourcesdir
    
    (cd out && cucumber_access_token="valid-token" gradle test)
    
    cat out/build/reports/cucumber-report.json | scrubCucumberReport | verifyJson || fail "Received report differed from verified snapshot"
}

testJavaApiKeyAuth() {
    filter "$FUNCNAME" || return 0

    local resourcesdir="out/src/test/resources/org/openapitools/client"
    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g java-cucumber --package-name Earth -i mocks/earth/openapi.yaml -o out -p cucumberTargetHost=http://localhost:5000
    mkdir -p $resourcesdir
    cp -r mocks/earth/features/* $resourcesdir
    
    (cd out && cucumber_api_key="valid-api-key" cucumber_security_scheme="ApiKeyAuth" gradle test)
    
    cat out/build/reports/cucumber-report.json | scrubCucumberReport | verifyJson || fail "Received report differed from verified snapshot"
}

testPythonAccessTokenAuth() {
    filter "$FUNCNAME" || return 0

    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g python-cucumber --package-name earth -i mocks/earth/openapi.yaml -o out -p cucumberTargetHost=http://localhost:5000
    cp -r mocks/earth/features/ out/test
    
    (cd out && pip install -r requirements.txt -r test-requirements.txt && cucumber_access_token="valid-token" pytest --cucumber-json cucumber-report.json)
    
    cat out/cucumber-report.json | scrubCucumberReport | verifyJson || fail "Received report differed from verified snapshot"
}

testPythonApiKeyAuth() {
    filter "$FUNCNAME" || return 0

    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g python-cucumber --package-name earth -i mocks/earth/openapi.yaml -o out -p cucumberTargetHost=http://localhost:5000
    cp -r mocks/earth/features/ out/test
    
    (cd out && pip install -r requirements.txt -r test-requirements.txt && cucumber_api_key="valid-api-key" cucumber_security_scheme="ApiKeyAuth" pytest --cucumber-json cucumber-report.json)
    
    cat out/cucumber-report.json | scrubCucumberReport | verifyJson || fail "Received report differed from verified snapshot"
}

testTypeScriptNodeAccessTokenAuth() {
    filter "$FUNCNAME" || return 0

    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g typescript-node-cucumber -i mocks/earth/openapi.yaml -o out -p cucumberTargetHost=http://localhost:5000 -p npmName=earth
    cp mocks/earth/features/*.feature out/features
    
    (cd out && npm install && npm run build && cucumber_access_token="valid-token" npx cucumber-js --format progress --format json:cucumber-report.json)
    
    cat out/cucumber-report.json | scrubCucumberReport | verifyJson || fail "Received report differed from verified snapshot"
}

testTypeScriptNodeApiKeyAuth() {
    filter "$FUNCNAME" || return 0

    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g typescript-node-cucumber -i mocks/earth/openapi.yaml -o out -p cucumberTargetHost=http://localhost:5000 -p npmName=earth
    cp mocks/earth/features/*.feature out/features
    
    (cd out && npm install && npm run build && cucumber_api_key="valid-api-key" cucumber_security_scheme="ApiKeyAuth" npx cucumber-js --format progress --format json:cucumber-report.json)
    
    cat out/cucumber-report.json | scrubCucumberReport | verifyJson || fail "Received report differed from verified snapshot"
}

tearDown() {
    rm -r out
}

oneTimeTearDown() {
    [ -n "$EARTH_PID" ] && kill "$EARTH_PID" 2>/dev/null
}

filter() {
  local name=$1

  if [ "$FILTER" != "" ] && ! echo "$name" | grep -qi "$FILTER"; then
    echo "Skipping $name (filtered by FILTER=$FILTER)"
    return 1
  fi

  return 0
}

scrubCucumberReport() {
    jq --indent 2 'map(.elements |= map(del(.start_timestamp?) | .steps |= map(del(.result.duration?, .result.error_message?)) | if .after then del(.after[].result.duration?) else . end))'
}

verifyJson() {
    local snapshotpath="snapshots/${FUNCNAME[1]}.verified.json"
    local receivedpath="${snapshotpath/.verified.json/.received.json}"

    cat | tee -i "$receivedpath" | jd "$snapshotpath"
}

. /usr/share/shunit2/shunit2