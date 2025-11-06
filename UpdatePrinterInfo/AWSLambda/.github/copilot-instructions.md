## Copilot Instructions for AWS Lambda Printer Ink Level Monitor

This document provides essential knowledge for AI coding agents to be immediately productive in the `AWS Lambda Printer Ink Level Monitor` codebase. 

### 1. Big Picture Architecture

The system consists of an AWS Lambda function (Java Spring Boot) acting as a POST endpoint. It receives printer ink status, processes it, and sends email notifications for low ink levels using JavaMail, while logging all information to a MySQL database.

- **Data Flow:** Encrypted header (user info, client ID) + JSON input (printer ink levels) -> Lambda (validation, parsing, logic) -> JavaMail (low ink notifications) & MySQL (logging).
- **Service Boundaries:** The Lambda function is a self-contained microservice. It communicates with an SMTP server for sending emails and a MySQL database as external dependencies.

### 2. Critical Developer Workflows

#### 2.1. Building the Java Spring Boot Application

To build the Java Spring Boot application into a deployable JAR, use Maven:

```bash
mvn clean install
```

This command will compile the code, run tests, and package the application into a JAR file in the `target/` directory.

#### 2.2. Deploying AWS Resources with Terraform

Navigate to the `terraform/` directory and use the following commands:

```bash
terraform init
terraform plan
terraform apply
```

- `terraform init`: Initializes the Terraform working directory.
- `terraform plan`: Shows an execution plan of what Terraform will do.
- `terraform apply`: Applies the changes required to reach the desired state of the configuration.

#### 2.3. Database Setup

The MySQL database and table can be created using the script located at `database/init.sql`. Execute this script against your MySQL instance.

### 3. Project-Specific Conventions and Patterns

- **Input Validation:** The Lambda handler is responsible for validating the encrypted header and the structure of the incoming JSON payload.
- **Ink Level Threshold:** A hardcoded threshold of 15% is used to determine low ink levels. This can be configured via `application.properties` for future flexibility.
- **Error Handling:** Implement robust error handling within the Lambda function to catch parsing errors, database connection issues, and email sending failures.

### 4. Integration Points and External Dependencies

- **JavaMail:** Used for sending email notifications. SMTP server details are configured in `application.properties`.
- **MySQL Database:** Used for persistent storage of printer status logs. Database connection details (host, port, username, password) are configured in `application.properties` and managed securely (e.g., via AWS Secrets Manager in a production environment).

### 5. Key Files and Directories

- `src/main/java/com/example/printerapp/LambdaHandler.java`: The entry point for the AWS Lambda function.
- `src/main/java/com/example/printerapp/service/PrinterInkService.java`: Contains the core business logic for processing ink levels, triggering email notifications, and saving to the database.
- `src/main/java/com/example/printerapp/model/PrinterStatus.java` & `Cartridge.java`: Data models for the incoming JSON payload.
- `src/main/resources/application.properties`: Spring Boot configuration file for database connection, SMTP server, etc.
- `terraform/main.tf`: Main Terraform configuration for AWS Lambda and IAM.
- `database/init.sql`: SQL script for creating the MySQL database and table.

