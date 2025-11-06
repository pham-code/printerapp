# AWS Lambda Printer Ink Level Monitor

This project implements an AWS Lambda service using Java Spring Boot to monitor printer ink levels. It processes incoming printer status data, triggers AWS SNS notifications for low ink levels, and logs all printer information to a MySQL database.

## Project Structure

```
.github/
├── copilot-instructions.md
src/
├── main/
│   ├── java/
│   │   └── com/
│   │       └── example/
│   │           └── printerapp/
│   │               ├── LambdaHandler.java
│   │               ├── PrinterAppApplication.java
│   │               ├── model/
│   │               │   ├── Cartridge.java
│   │               │   └── PrinterStatus.java
│   │               └── service/
│   │                   └── PrinterInkService.java
│   └── resources/
│       └── application.properties
├── test/
│   └── java/
│       └── com/
│           └── example/
│               └── printerapp/
│                   └── PrinterAppApplicationTests.java
terraform/
├── main.tf
├── variables.tf
└── outputs.tf
database/
└── init.sql
pom.xml
README.md
```

## Components

### 1. AWS Lambda Service (Java Spring Boot)

A POST endpoint that accepts encrypted user information and client ID in the header for validation. It processes a JSON string containing printer ink level information. If any cartridge level is below 15%, an email notification is sent using JavaMail. All printer information and execution timestamps are saved to a MySQL database.

**Technologies:** Java, Spring Boot, AWS Lambda, JavaMail, MySQL.

### 2. Terraform Script for AWS Lambda Deployment

Manages the deployment of the AWS Lambda function, including its IAM role with necessary permissions for Lambda invocation and MySQL interaction.

### 3. MySQL Database and Table Creation Script

Provides a script to create the `printer_ink_db` database and the `printer_status_logs` table with a schema designed to store printer ink level logs.

## Setup and Deployment

Detailed instructions for setting up the development environment, building the Java application, and deploying the AWS resources using Terraform will be provided in subsequent sections.

## Example JSON Input for Lambda

```json
{
    "ip_address": "192.168.1.11",
    "make": "Brother",
    "model": "MFC-J6535DW",
    "description": "Brother NC-390w, Firmware Ver.ZC  ,MID 8CH-121-001",
    "cartridges": [
        {
            "name": "Black Ink Cartridge",
            "level": "20%",
            "color": "black"
        },
        {
            "name": "Cyan Ink Cartridge",
            "level": "N/A",
            "color": "cyan"
        },
        {
            "name": "Magenta Ink Cartridge",
            "level": "12%",
            "color": "magenta"
        },
        {
            "name": "Yellow Ink Cartridge",
            "level": "N/A",
            "color": "yellow"
        }
    ]
}
```

## Sample Endpoint Execution

To test the Lambda function, you can use a tool like `curl`. Replace `YOUR_API_GATEWAY_URL` with the actual URL of your deployed API Gateway endpoint.

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-Encrypted-Key: valid-encrypted-key" \
  -H "X-User-Id: 12345" \
  -d '{
    "ip_address": "192.168.1.11",
    "make": "Brother",
    "model": "MFC-J6535DW",
    "description": "Brother NC-390w, Firmware Ver.ZC  ,MID 8CH-121-001",
    "cartridges": [
        {
            "name": "Black Ink Cartridge",
            "level": "20%",
            "color": "black"
        },
        {
            "name": "Cyan Ink Cartridge",
            "level": "N/A",
            "color": "cyan"
        },
        {
            "name": "Magenta Ink Cartridge",
            "level": "12%",
            "color": "magenta"
        },
        {
            "name": "Yellow Ink Cartridge",
            "level": "N/A",
            "color": "yellow"
        }
    ]
}' \
  YOUR_API_GATEWAY_URL/dev/printer-status
```
