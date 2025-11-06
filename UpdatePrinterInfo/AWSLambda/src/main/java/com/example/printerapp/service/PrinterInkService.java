package com.example.printerapp.service;

import com.example.printerapp.model.Cartridge;
import com.example.printerapp.model.PrinterStatus;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class PrinterInkService {

    private static final Logger logger = LoggerFactory.getLogger(PrinterInkService.class);

    @Autowired
    private JavaMailSender javaMailSender;

    @Value("${spring.datasource.url}")
    private String databaseUrl;

    @Value("${spring.datasource.username}")
    private String databaseUsername;

    @Value("${spring.datasource.password}")
    private String databasePassword;

    private static final int LOW_INK_THRESHOLD = 15;

    /**
     * Processes the printer status, checks for low ink levels, sends notifications, and logs the status.
     *
     * @param userId        The ID of the user associated with the printer.
     * @param printerStatus The printer status object containing ink levels and other details.
     */
    public void processPrinterStatus(Long userId, PrinterStatus printerStatus) throws Exception {
        boolean lowInkDetected = false;
        StringBuilder notificationMessage = new StringBuilder();
        notificationMessage.append("Printer ").append(printerStatus.getMake()).append(" ").append(printerStatus.getModel()).append(" (").append(printerStatus.getIp_address()).append(") ink status:\n");
        logger.info("Processing printer status for user ID: {}", userId);

        for (Cartridge cartridge : printerStatus.getCartridges()) {
            int inkLevel = parseInkLevel(cartridge.getLevel());
            String statusMessage;
            boolean emailSent = false;

            logger.debug("Processing cartridge: {} with level: {}", cartridge.getName(), cartridge.getLevel());

            if (inkLevel != -1 && inkLevel < LOW_INK_THRESHOLD) {
                lowInkDetected = true;
                statusMessage = "Ink low, email sent";
                notificationMessage.append("- ").append(cartridge.getName()).append(" (").append(cartridge.getColor()).append("): ").append(cartridge.getLevel()).append(" - LOW!\n");
                emailSent = true;
            } else if (inkLevel == -1) {
                statusMessage = "Ink level N/A";
                notificationMessage.append("- ").append(cartridge.getName()).append(" (").append(cartridge.getColor()).append("): ").append(cartridge.getLevel()).append(" - N/A\n");
            } else {
                statusMessage = "Ink level OK";
                notificationMessage.append("- ").append(cartridge.getName()).append(" (").append(cartridge.getColor()).append("): ").append(cartridge.getLevel()).append(" - OK\n");
            }
            savePrinterLog(userId, printerStatus.getIp_address(), cartridge.getName(), inkLevel, statusMessage, emailSent);
        }

        logger.info("Low ink detected: {}", lowInkDetected);
        if (lowInkDetected) {
            sendEmail(notificationMessage.toString());
        }
    }

    /**
     * Parses the ink level percentage from a string (e.g., "20%").
     *
     * @param level The string representation of the ink level.
     * @return The ink level as an integer, or -1 if not applicable or not found.
     */
    private int parseInkLevel(String level) {
        if (level == null || level.equalsIgnoreCase("N/A")) {
            return -1;
        }
        Pattern pattern = Pattern.compile("(\\d+)%");
        Matcher matcher = pattern.matcher(level);
        if (matcher.find()) {
            return Integer.parseInt(matcher.group(1));
        }
        return -1;
    }

    /**
     * Sends an email notification using JavaMailSender.
     *
     * @param message The content of the email.
     */
    private void sendEmail(String message) throws Exception {
        String fromEmail = "bryanpham2000@gmail.com";
        String toEmail = "bryan_pham2000@yahoo.com";
        try {
            logger.info("Sending email from {}", fromEmail);
            SimpleMailMessage mailMessage = new SimpleMailMessage();
            mailMessage.setTo(toEmail);
            mailMessage.setFrom(fromEmail);
            mailMessage.setSubject("Printer Ink Level Alert");
            mailMessage.setText(message);
            javaMailSender.send(mailMessage);
            logger.info("Email sent to {}", toEmail);
        } catch (Exception e) {
            logger.error("Error sending email to {}", toEmail, e);
            throw e;
        }
    }

    /**
     * Saves a printer status log to the database.
     *
     * @param userId             The ID of the user.
     * @param printerIp          The IP address of the printer.
     * @param cartridgeId        The ID or name of the cartridge.
     * @param inkLevelPercentage The ink level percentage.
     * @param statusMessage      A message describing the status.
     * @param emailSent          A boolean indicating if an email was sent.
     */
    private void savePrinterLog(Long userId, String printerIp, String cartridgeId, int inkLevelPercentage, String statusMessage, boolean emailSent) throws SQLException {
        String sql = "INSERT INTO printer_status_logs (user_id, printer_ip, cartridge_id, ink_level_percentage, status_message, execution_timestamp, email_sent) VALUES (?, ?, ?, ?, ?, ?, ?)";
        logger.debug("Saving printer log for printer IP: {}", printerIp);
        try (Connection conn = DriverManager.getConnection(databaseUrl, databaseUsername, databasePassword);
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setLong(1, userId);
            pstmt.setString(2, printerIp);
            pstmt.setString(3, cartridgeId);
            pstmt.setInt(4, inkLevelPercentage);
            pstmt.setString(5, statusMessage);
            pstmt.setTimestamp(6, Timestamp.valueOf(LocalDateTime.now()));
            pstmt.setBoolean(7, emailSent);
            pstmt.executeUpdate();
            logger.info("Printer log saved for printer: {}", printerIp);
        } catch (SQLException e) {
            logger.error("Error saving printer log for printer IP: {}", printerIp, e);
            throw e;
        }
    }
}
