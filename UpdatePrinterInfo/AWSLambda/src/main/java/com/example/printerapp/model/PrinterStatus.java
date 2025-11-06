package com.example.printerapp.model;

import lombok.Data;

import java.util.List;

@Data
public class PrinterStatus {
    private String ip_address;
    private String make;
    private String model;
    private String description;
    private List<Cartridge> cartridges;
}
