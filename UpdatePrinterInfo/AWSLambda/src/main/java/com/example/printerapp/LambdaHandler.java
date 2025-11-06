package com.example.printerapp;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyRequestEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyResponseEvent;
import com.example.printerapp.model.PrinterStatus;
import com.example.printerapp.service.PrinterInkService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.ApplicationContext;


import java.util.HashMap;
import java.util.Map;

public class LambdaHandler implements RequestHandler<APIGatewayProxyRequestEvent, APIGatewayProxyResponseEvent> {

    private static final Logger logger = LoggerFactory.getLogger(LambdaHandler.class);
    private static final ApplicationContext applicationContext = new SpringApplicationBuilder(PrinterAppApplication.class)
            .web(WebApplicationType.NONE)
            .run();

    private final PrinterInkService printerInkService;
    private final ObjectMapper objectMapper;

    public LambdaHandler() {
        this.printerInkService = applicationContext.getBean(PrinterInkService.class);
        this.objectMapper = new ObjectMapper();
    }

    /**
     * Handles the incoming API Gateway request, processes the printer status, and returns a response.
     *
     * @param request The incoming API Gateway request.
     * @param context The Lambda execution context.
     * @return An API Gateway response object.
     */
    @Override
    public APIGatewayProxyResponseEvent handleRequest(APIGatewayProxyRequestEvent request, Context context) {
        APIGatewayProxyResponseEvent response = new APIGatewayProxyResponseEvent();
        Map<String, String> headers = new HashMap<>();
        headers.put("Content-Type", "application/json");
        response.setHeaders(headers);

        try {
            // Validate encrypted header (simplified for example)
            String encryptedHeader = request.getHeaders().get("X-Encrypted-Key");
            String userIdHeader = request.getHeaders().get("X-User-Id");
            logger.info("X-Encrypted-Key: {}", encryptedHeader);
            logger.info("X-User-Id: {}", userIdHeader);

            Long userId = null;
            if (userIdHeader != null) {
                try {
                    userId = Long.parseLong(userIdHeader);
                } catch (NumberFormatException e) {
                    logger.error("Invalid X-User-Id header format: {}", userIdHeader, e);
                    return response.withStatusCode(400).withBody("{\"message\": \"Bad Request: Invalid X-User-Id format\"}");
                }
            }

            if (encryptedHeader == null || !isValidHeader(encryptedHeader)) {
                return response.withStatusCode(401).withBody("{\"message\": \"Unauthorized: Invalid or missing encrypted key\"}");
            }

            logger.info("Request Body: {}", request.getBody());
            PrinterStatus printerStatus = objectMapper.readValue(request.getBody(), PrinterStatus.class);
            printerInkService.processPrinterStatus(userId, printerStatus);

            return response.withStatusCode(200).withBody("{\"message\": \"Printer status processed successfully\"}");
        } catch (Exception e) {
            logger.error("Error processing printer status", e);
            return response.withStatusCode(500).withBody("{\"message\": \"Error processing printer status : " + e.getMessage() + "\"}");
        }
    }

    /**
     * Validates the encrypted header.
     *
     * @param encryptedHeader The encrypted header string.
     * @return True if the header is valid, false otherwise.
     */
    private boolean isValidHeader(String encryptedHeader) {
        // Implement actual decryption and validation logic here
        // For demonstration, a simple check
        return encryptedHeader.equals("valid-encrypted-key");
    }
}
