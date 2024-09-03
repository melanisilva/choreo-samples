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

// HTTP client configuration to call the external SCIM2 Users endpoint
http:Client asgardeoClient = check new("https://dev.api.asgardeo.io/t/orgshanthird"
);

service / on new http:Listener(8090) {

    // Existing GET resource
    resource function get .(string name) returns Greeting {
        Greeting greetingMessage = {"from": "Choreo", "to": name, "message": "Welcome to Choreo!"};
        return greetingMessage;
    }

    // New POST resource to create a user and call SCIM2 Users endpoint
    resource function post createUser(http:Caller caller, http:Request req) returns error? {
        // Read the payload and attempt to convert it to the desired type
        json payloadJson = check req.getJsonPayload();

        // Explicitly specify the target type for conversion
        var conversionResult = payloadJson.fromJsonWithType(CreateAsgardeoUserPayload);
        if (conversionResult is CreateAsgardeoUserPayload) {
            CreateAsgardeoUserPayload payload = conversionResult;
            log:printInfo("Payload received: " + payload.toString());

            // Extract givenName and familyName from the payload
            string givenName = payload.name.givenName;
            string familyName = payload.name.familyName;

            // Construct a new payload for the SCIM2 Users endpoint
            json scim2UserPayload = {
                "name": {
                    "givenName": givenName,
                    "familyName": familyName
                },
                "userName": payload.userName,
                "password": "bairE123@",
                "emails": [
                    {
                        "value": payload.email.value,
                        "primary": payload.email.primary
                    }
                ]
            };

            // Set the Authorization header with the provided token
            http:Request newUserRequest = new;
            newUserRequest.setHeader("Authorization", "Bearer cd6de198-aab8-3f71-809d-77803424b1b2");
            newUserRequest.setJsonPayload(scim2UserPayload);

            // Call the SCIM2 Users endpoint with explicit type descriptor
            http:Response|http:ClientError scim2Response = asgardeoClient->post("/scim2/Users", newUserRequest);

            if (scim2Response is http:Response) {
                // Forward the response directly to the caller
                check caller->respond(scim2Response);
            } else {
                log:printError("Error calling SCIM2 Users endpoint: ", 'error = scim2Response);
                json errorResponse = { "error": "Failed to create user at SCIM2 endpoint" };
                check caller->respond(errorResponse);
            }

        } else {
            log:printError("Error converting payload: ", 'error = conversionResult);
            json errorResponse = { "error": "Invalid payload format" };
            check caller->respond(errorResponse);
        }
    }
}
