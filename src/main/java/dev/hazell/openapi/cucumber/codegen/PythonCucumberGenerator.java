package dev.hazell.openapi.cucumber.codegen;

import org.openapitools.codegen.*;
import org.openapitools.codegen.languages.*;

import java.io.File;

public class PythonCucumberGenerator extends PythonClientCodegen {

    public PythonCucumberGenerator() {
        super();
        
        templateDir = "python-cucumber";
    }

    @Override
    public String getName() {
        return "python-cucumber";
    }

    @Override
    public String getHelp() {
        return "Custom Python generator with Cucumber tests.";
    }

    @Override
    public void processOpts() {
        super.processOpts();

        final String defaultEnvFolder = "env" + File.separatorChar + "default";
        supportingFiles.add(new SupportingFile("test-requirements.mustache", "", "test-requirements.txt"));
        supportingFiles.add(new SupportingFile("cucumber_steps.mustache", "test", "test_cucumber.py"));
    }
}