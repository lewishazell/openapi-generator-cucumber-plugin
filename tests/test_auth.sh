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

    node mocks/earth/app.js &>/dev/null &
    EARTH_PID=$!
}

setUp() {
    mkdir -p out
}

testCSharpAccessTokenAuth() {
    filter "$FUNCNAME" || return 0

    local testdir="out/src/Earth.Test"
    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g csharp-cucumber --package-name Earth -i mocks/earth/openapi.yaml -o out -p cucumberTargetHost=http://localhost:3000
    cp -r mocks/earth/features/ "$testdir/Features"
    
    (cd "$testdir" && cucumber_access_token="valid-token" dotnet test) | scrubCSharpTestOutput | verifyText || fail "Received report differed from verified snapshot"
}

testCSharpApiKeyAuth() {
    filter "$FUNCNAME" || return 0

    local testdir="out/src/Earth.Test"
    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g csharp-cucumber --package-name Earth -i mocks/earth/openapi.yaml -o out -p cucumberTargetHost=http://localhost:3000
    cp -r mocks/earth/features/ "$testdir/Features"
    
    (cd "$testdir" && cucumber_api_key="valid-api-key" cucumber_security_scheme="x-api-key" dotnet test) | scrubCSharpTestOutput | verifyText || fail "Received report differed from verified snapshot"
}

testGoAccessTokenAuth() {
    filter "$FUNCNAME" || return 0

    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g go-cucumber --package-name earth -i mocks/earth/openapi.yaml -o out -p cucumberTargetHost=http://localhost:3000
    cp -r mocks/earth/features/ out/test/features
    
    (cd out && go get -u -v all && cd test && cucumber_access_token="valid-token" go test) | scrubGoTestOutput | verifyText || fail "Received report differed from verified snapshot"
}

testGoApiKeyAuth() {
    filter "$FUNCNAME" || return 0

    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g go-cucumber --package-name earth -i mocks/earth/openapi.yaml -o out -p cucumberTargetHost=http://localhost:3000
    cp -r mocks/earth/features/ out/test/features
    
    (cd out && go get -u -v all && cd test && cucumber_api_key="valid-api-key" cucumber_security_scheme="ApiKeyAuth" go test) | scrubGoTestOutput | verifyText || fail "Received report differed from verified snapshot"
}

testJavaAccessTokenAuth() {
    filter "$FUNCNAME" || return 0

    local resourcesdir="out/src/test/resources/org/openapitools/client"
    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g java-cucumber --package-name Earth -i mocks/earth/openapi.yaml -o out -p cucumberTargetHost=http://localhost:3000
    mkdir -p $resourcesdir
    cp -r mocks/earth/features/* $resourcesdir
    
    (cd out && cucumber_access_token="valid-token" gradle test) | scrubGradleTestOutput | verifyText || fail "Received report differed from verified snapshot"
}

testJavaApiKeyAuth() {
    filter "$FUNCNAME" || return 0

    local resourcesdir="out/src/test/resources/org/openapitools/client"
    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g java-cucumber --package-name Earth -i mocks/earth/openapi.yaml -o out -p cucumberTargetHost=http://localhost:3000
    mkdir -p $resourcesdir
    cp -r mocks/earth/features/* $resourcesdir
    
    (cd out && cucumber_api_key="valid-api-key" cucumber_security_scheme="ApiKeyAuth" gradle test) | scrubGradleTestOutput | verifyText || fail "Received report differed from verified snapshot"
}

testPythonAccessTokenAuth() {
    filter "$FUNCNAME" || return 0

    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g python-cucumber --package-name earth -i mocks/earth/openapi.yaml -o out -p cucumberTargetHost=http://localhost:3000
    cp -r mocks/earth/features/ out/test
    
    (cd out && pip install -r requirements.txt -r test-requirements.txt && cucumber_access_token="valid-token" pytest) | scrubPythonTestOutput | verifyText || fail "Received report differed from verified snapshot"
}

testPythonApiKeyAuth() {
    filter "$FUNCNAME" || return 0

    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g python-cucumber --package-name earth -i mocks/earth/openapi.yaml -o out -p cucumberTargetHost=http://localhost:3000
    cp -r mocks/earth/features/ out/test
    
    (cd out && pip install -r requirements.txt -r test-requirements.txt && cucumber_api_key="valid-api-key" cucumber_security_scheme="ApiKeyAuth" pytest) | scrubPythonTestOutput | verifyText || fail "Received report differed from verified snapshot"
}

testTypeScriptNodeAccessTokenAuth() {
    filter "$FUNCNAME" || return 0

    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g typescript-node-cucumber -i mocks/earth/openapi.yaml -o out -p cucumberTargetHost=http://localhost:3000 -p npmName=earth
    cp mocks/earth/features/*.feature out/features
    
    (cd out && npm install > /dev/null && cucumber_access_token="valid-token" npm test) | scrubTypeScriptNodeTestOutput | verifyText || fail "Received report differed from verified snapshot"
}

testTypeScriptNodeApiKeyAuth() {
    filter "$FUNCNAME" || return 0

    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g typescript-node-cucumber -i mocks/earth/openapi.yaml -o out -p cucumberTargetHost=http://localhost:3000 -p npmName=earth
    cp mocks/earth/features/*.feature out/features
    
    (cd out && npm install > /dev/null && cucumber_api_key="valid-api-key" cucumber_security_scheme="ApiKeyAuth" npm test) | scrubTypeScriptNodeTestOutput | verifyText || fail "Received report differed from verified snapshot"
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

scrubCSharpTestOutput() {
    cat | sed -n '/A total of 1 test files matched the specified pattern\./,$p' | sed -E 's/in .*\.cs://; s/\[[0-9]+ ms\]//g; s/Duration: [0-9]+ ms//g; s/\([0-9].[0-9]s\)//g; s/\(net[0-9]+\.[0.9]+\)//'
}

scrubGoTestOutput() {
    cat | sed -r 's/\x1B\[[0-9;]*[mK]//g' | sed -E 's/\(?[0-9]+.[0-9]+s\)?//g; s/[0-9]+\.[0-9]+ms//g; s/\.feature:[0-9]+/.feature/g; s/\.go:[0-9]+/.go/g'
}

scrubGradleTestOutput() {
    cat | sed -E 's/\[Incubating\] Problems report is available at.*//g'
}

scrubPythonTestOutput() {
    cat | sed -n '/\.py/,$p' | sed -E 's/.*fixtures\.py:[0-9]+://g; s/\.py:[0-9]+/\.py/g; s/0[xX][0-9a-fA-F]+//g; s/ in [0-9]+\.[0-9]+s//g; s/E .*//g'
}

scrubTypeScriptNodeTestOutput() {
    cat | sed -r 's/\x1B\[[0-9;]*[mK]//g' | sed -E 's/at .*\.js:[0-9]+:[0-9]+\)//g; s/[0-9]+m[0-9]+\.[0-9]+s//g; s/\.feature:[0-9]+/.feature/g; s/\.js:[0-9]+/.js/g'
}

verifyText() {
    local snapshotpath="snapshots/${FUNCNAME[1]}.verified.txt"
    local receivedpath="${snapshotpath/.verified.txt/.received.txt}"

    cat | tee "$receivedpath"
    diff -q "$receivedpath" "$snapshotpath" > /dev/null
}

. /usr/share/shunit2/shunit2