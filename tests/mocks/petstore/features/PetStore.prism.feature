Feature: PetStore API
The developer must be able to programmatically manage pets at the pet store

Scenario: Successfully find a pet at the pet store
This scenario ensures that the user can successfully retrieve a pet from the store by its ID.

Given there is a "findPetById" request for the "DefaultApi"
And the "id" parameter has a value of "1"
When the request is sent
Then the response status should be 200
And the response content should be:
  """
  {"name":"string","tag":"string","id":-9007199254740991}
  """

Scenario: Successfully find a pet at the pet store with an incorrect response status
This scenario ensures that the user can successfully retrieve a pet from the store by its ID, but asserts an incorrect response status.

Given there is a "findPetById" request for the "DefaultApi"
And the "id" parameter has a value of "1"
When the request is sent
Then the response status should be 201
And the response content should be:
  """
  {"name":"string","tag":"string","id":-9007199254740991}
  """

Scenario: Successfully find a pet at the pet store with an incorrect response content
This scenario ensures that the user can successfully retrieve a pet from the store by its ID, but asserts an incorrect response content.

Given there is a "findPetById" request for the "DefaultApi"
And the "id" parameter has a value of "1"
When the request is sent
Then the response status should be 200
And the response content should be:
  """
  {"name":"Pickle","tag":"cat","id":1}
  """

Scenario: Successfully delete a pet from the pet store
This scenario verifies that a pet can be deleted successfully from the pet store using its ID.

Given there is a "deletePet" request for the "DefaultApi"
And the "id" parameter has a value of "1"
When the request is sent
Then the response status should be 204

Scenario: Successfully list all pets at the pet store with a matching tag
This scenario checks that the user can list pets at the pet store that match specified tags.

Given there is a "findPets" request for the "DefaultApi"
And the "tags" parameter has the following values:
    | value |
    |-------|
    | cat   |
    | dog   |
And the "limit" parameter has a value of "2"
When the request is sent
Then the response status should be 200
And the response content should be:
  """
  [{"name":"string","tag":"string","id":-9007199254740991}]
  """

Scenario: Successfully list all pets at the pet store with a matching tag with no limit
This scenario tests the ability to list all pets matching specified tags, but without any limits on the number of results.

Given there is a "findPets" request for the "DefaultApi"
And the "tags" parameter has the following values:
    | value |
    |-------|
    | cat   |
    | dog   |
When the request is sent
Then the response status should be 200

Scenario: Successfully add a pet to the pet store
This scenario ensures that a pet can be successfully added to the pet store.

Given there is an "addPet" request for the "DefaultApi"
And the "PetDetails" parameter has a JSON value of:
  """
  {"name": "Pickle", "tag": "cat"}
  """
When the request is sent
Then the response status should be 200

Scenario: Successfully upload a picture of a pet
This scenario ensures that a picture of a pet can be successfully uploaded to the pet store.

Given there is an "addPetPhotoById" request for the "DefaultApi"
And the "id" parameter has a value of "1"
And the "file" parameter is the file "photo.jpg"
When the request is sent
Then the response status should be 201

Scenario: Verify pet response contains expected fields
This scenario ensures that the response contains specific fields (e.g., "name" and "tag") without requiring an exact match for the entire JSON.

Given there is a "findPetById" request for the "DefaultApi"
And the "id" parameter has a value of "1"
When the request is sent
Then the response status should be 200
And the response content should contain the subtree:
  """
  {"name":"string","tag":"string"}
  """

Scenario: Verify pet response contains nested subtree
This scenario ensures that the response contains a nested subtree (e.g., a "category" object with an "id" and "name").

Given there is a "findPetById" request for the "DefaultApi"
And the "id" parameter has a value of "1"
When the request is sent
Then the response status should be 200
And the response content should contain the subtree:
  """
  {"tag":"string"}
  """

Scenario: Verify pet list response contains at least one matching pet
This scenario ensures that a list response contains at least one pet with specific fields (e.g., a pet with "name: string").

Given there is a "findPets" request for the "DefaultApi"
And the "tags" parameter has the following values:
    | value |
    |-------|
    | cat   |
When the request is sent
Then the response status should be 200
And the response content should contain the subtree:
  """
  [{"name":"string"}]
  """

Scenario: Chain JSON response data to request parameters using JSON Path
This scenario verifies that a value from a previous response can be chained to a subsequent request using JSON Path.

Given there is an "addPet" request for the "DefaultApi"
And the "PetDetails" parameter has a JSON value of:
  """
  {"name": "Pickle", "tag": "cat"}
  """
When the request is sent
Then the response status should be 200

Given there is a "findPetById" request for the "DefaultApi"
And the "id" parameter is "$.id" from the previous response
When the request is sent
Then the response status should be 200