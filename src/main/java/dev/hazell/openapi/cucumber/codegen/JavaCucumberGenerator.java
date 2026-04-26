package dev.hazell.openapi.cucumber.codegen;

import org.openapitools.codegen.*;
import org.openapitools.codegen.languages.*;

import java.io.File;

public class JavaCucumberGenerator extends JavaClientCodegen {

    public JavaCucumberGenerator() {
        super();

        templateDir = "java-cucumber";
    }

    @Override
    public String getName() {
        return "java-cucumber";
    }

    @Override
    public String getHelp() {
        return "Custom Java generator with Cucumber tests.";
    }

    @Override
    public void processOpts() {
        super.processOpts();

        String testFileFolder = (testFolder + File.separator + getInvokerPackage().replace(".", File.separator)).replace("/", File.separator);
        
        supportingFiles.add(new SupportingFile("pom.mustache", "", "pom.xml"));
        supportingFiles.add(new SupportingFile("build.gradle.mustache", "", "build.gradle"));
        supportingFiles.add(new SupportingFile("cucumber_steps.mustache", testFileFolder, "StepDefinitions.java"));
        supportingFiles.add(new SupportingFile("cucumber_test.mustache", testFileFolder, "RunCucumberTest.java"));
    }
}