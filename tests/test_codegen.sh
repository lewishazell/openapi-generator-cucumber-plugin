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

    prism mock petstore-extended.yaml &>/dev/null &
    PRISM_PID=$!
}

setUp() {
    mkdir -p out
}

testCSharpCodegen() {
    filter "$FUNCNAME" || return 0

    local testdir="out/src/PetStore.Test"
    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g csharp-cucumber --package-name PetStore -i petstore-extended.yaml -o out -p cucumberTargetHost=http://localhost:4010
    cp -r features/ "$testdir/Features"

    (cd out && dotnet test)

    cat $testdir/bin/Debug/*/reqnroll_report.ndjson | cucumber-json-formatter | scrubCucumberReport | verifyJson || fail "Received output differed from verified snapshot"
}

testGoCodegen() {
    filter "$FUNCNAME" || return 0

    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g go-cucumber --package-name petstore -i petstore-extended.yaml -o out -p cucumberTargetHost=http://localhost:4010
    cp -r features/ out/test/features
    
    (cd out && go get -u -v all && go test ./... -godog.format=cucumber:report.json)
    
    cat out/test/report.json | scrubCucumberReport | verifyJson || fail "Received output differed from verified snapshot"
}

testJavaCodegenWithGradle() {
    filter "$FUNCNAME" || return 0

    local resourcesdir="out/src/test/resources/org/openapitools/client"
    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g java-cucumber --package-name PetStore -i petstore-extended.yaml -o out -p cucumberTargetHost=http://localhost:4010
    mkdir -p $resourcesdir
    cp -r features/* $resourcesdir
    
    (cd out && gradle test)
    
    cat out/build/reports/cucumber-report.json | scrubCucumberReport | verifyJson || fail "Received report differed from verified snapshot"
}

testJavaCodegenWithMaven() {
    filter "$FUNCNAME" || return 0

    local resourcesdir="out/src/test/resources/org/openapitools/client"
    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g java-cucumber --package-name PetStore -i petstore-extended.yaml -o out -p cucumberTargetHost=http://localhost:4010
    mkdir -p $resourcesdir
    cp -r features/* $resourcesdir
    
    (cd out && mvn test)
    
    cat out/target/cucumber-report.json | scrubCucumberReport | verifyJson || fail "Received report differed from verified snapshot"
}

testPythonCodegen() {
    filter "$FUNCNAME" || return 0

    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g python-cucumber --package-name petstore -i petstore-extended.yaml -o out -p cucumberTargetHost=http://localhost:4010
    cp -r features/ out/test

    (cd out && pip install -r requirements.txt -r test-requirements.txt && pytest --cucumber-json cucumber-report.json)
    
    cat out/cucumber-report.json | scrubCucumberReport | verifyJson || fail "Received report differed from verified snapshot"
}

testTypeScriptNodeCodegen() {
    filter "$FUNCNAME" || return 0

    openapi-generator-cli --custom-generator "$JAR_FILE" generate -g typescript-node-cucumber -i petstore-extended.yaml -o out -p cucumberTargetHost=http://localhost:4010 -p npmName=petstore
    cp features/*.feature out/features

    (cd out && npm install && npx cucumber-js --format progress --format json:cucumber-report.json)
    
    cat out/cucumber-report.json | scrubCucumberReport | verifyJson || fail "Received report differed from verified snapshot"
}

tearDown() {
    rm -r out
}

oneTimeTearDown() {
    [ -n "$PRISM_PID" ] && kill "$PRISM_PID" 2>/dev/null
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
    jq --indent 2 'map(.elements |= map(del(.start_timestamp?) | .steps |= map(del(.result.duration?, .result.error_message?))))'
}

verifyJson() {
    local snapshotpath="snapshots/${FUNCNAME[1]}.verified.json"
    local receivedpath="${snapshotpath/.verified.json/.received.json}"

    cat | tee -i "$receivedpath" | jd "$snapshotpath"
}

. /usr/share/shunit2/shunit2