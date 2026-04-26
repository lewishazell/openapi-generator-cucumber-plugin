package dev.hazell.openapi.cucumber.codegen;

import org.openapitools.codegen.*;
import org.openapitools.codegen.languages.*;

import java.io.File;

public class GoCucumberGenerator extends GoClientCodegen {

    public GoCucumberGenerator() {
        super();
        
        templateDir = "go-cucumber";
    }

    @Override
    public String getName() {
        return "go-cucumber";
    }

    @Override
    public String getHelp() {
        return "Custom go generator with Cucumber tests.";
    }

    @Override
    public void processOpts() {
        super.processOpts();

        supportingFiles.add(new SupportingFile("cucumber_steps.mustache", "test", "godogs_test.go"));
    }
}