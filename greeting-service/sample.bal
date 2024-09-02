import ballerina/http;
import ballerina/log;

type Greeting record {
    string 'from;
    string to;
    string message;
};

type CreateAsgardeoUserPayload record {
    record {
        string value;
        boolean primary;
    } email;
    record {
        string givenName;
        string familyName;
    } name;
    string userName;
    string correlationID;
};

service / on new http:Listener(8090) {

    // Existing GET resource
    resource function get .(string name) returns Greeting {
        Greeting greetingMessage = {"from": "Choreo", "to": name, "message": "Welcome to Choreo!"};
        return greetingMessage;
    }

    // New POST resource to create a user
    resource function post createUser(http:Caller caller, http:Request req) returns error? {
        // Read the payload and attempt to convert it to the desired type
        json payloadJson = check req.getJsonPayload();
        CreateAsgardeoUserPayload payload;

        var conversionResult = payloadJson.fromJsonWithType(CreateAsgardeoUserPayload);
        if (conversionResult is CreateAsgardeoUserPayload) {
            payload = conversionResult;
            log:printInfo("Payload received: " + payload.toString());

            // Processing logic (e.g., creating a user in Asgardeo)
            // For now, we will simply log the payload and send a response back.

            // Constructing a response
            json responseJson = {
                "status": "User created successfully",
                "userName": payload.userName,
                "email": payload.email.value
            };

            // Send the response back to the caller
            check caller->respond(responseJson);
        } else {
            log:printError("Error converting payload: ", 'error = conversionResult);
            json errorResponse = { "error": "Invalid payload format" };
            check caller->respond(errorResponse);
        }
    }
}
