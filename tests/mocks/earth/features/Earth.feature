Feature: Earth Supercomputer API

Scenario: Successfully get the meaning of life

Given there is a "getTheMeaningOfLife" request for the "DefaultApi"
When the request is sent
Then the response status should be 200
And the response content should be:
    """
    { "meaning": "42" }
    """
