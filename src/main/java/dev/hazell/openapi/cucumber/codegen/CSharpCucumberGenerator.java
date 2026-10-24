package dev.hazell.openapi.cucumber.codegen;

import org.openapitools.codegen.*;
import org.openapitools.codegen.languages.*;

import java.io.File;

public class CSharpCucumberGenerator extends CSharpClientCodegen {

    public CSharpCucumberGenerator() {
        super();

        // The generated step definitions target the `generichost` client API.
        // Pin the library so the generated client surface is stable across
        // OpenAPI Generator versions. Pass `-p library=<name>` to override, but
        // note the step templates only compile against `generichost`.
        library = "generichost";
        templateDir = "csharp-cucumber";
    }

    @Override
    public String getName() {
        return "csharp-cucumber";
    }

    @Override
    public String getHelp() {
        return "Custom C# generator with Cucumber tests.";
    }

    @Override
    public void processOpts() {
        super.processOpts();
        
        final String testPackageName = testPackageName();
        final String testPackageFolder = testFolder + File.separator + testPackageName;
        supportingFiles.add(new SupportingFile("netcore_testproject.mustache", testPackageFolder, testPackageName + ".csproj"));
        supportingFiles.add(new SupportingFile("cucumber_steps.mustache", testPackageFolder, "StepDefinitions.cs"));
        supportingFiles.add(new SupportingFile("reqnroll.mustache", testPackageFolder, "reqnroll.json"));
    }
}