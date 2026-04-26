package dev.hazell.openapi.cucumber.codegen;

import org.openapitools.codegen.*;
import org.openapitools.codegen.languages.*;
import java.io.File;

public class TypeScriptNodeCucumberGenerator extends TypeScriptNodeClientCodegen {

    public TypeScriptNodeCucumberGenerator() {
        super();
        
        templateDir = "typescript-node-cucumber";
    }

    @Override
    public String getName() {
        return "typescript-node-cucumber";
    }

    @Override
    public String getHelp() {
        return "Custom TypeScriptNode generator with Cucumber tests.";
    }

    @Override
    public void processOpts() {
        super.processOpts();

        supportingFiles.add(new SupportingFile("tsconfig.mustache", "", "tsconfig.json"));
        supportingFiles.add(new SupportingFile("package.mustache", "", "package.json"));
        supportingFiles.add(new SupportingFile("cucumber_steps.mustache", "features/step_definitions", "steps.ts"));
    }
}