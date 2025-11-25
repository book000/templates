package com.example;

import org.apache.commons.lang3.StringUtils;

public class App {
    public static void main(String[] args) {
        System.out.println("Testing Maven CI workflow");
        
        String testString = "hello world";
        String capitalized = StringUtils.capitalize(testString);
        System.out.println("Capitalized: " + capitalized);
        
        // Simple test
        if (StringUtils.isNotEmpty(testString)) {
            System.out.println("String is not empty: " + testString);
        }
        
        System.out.println("Maven test completed successfully");
    }
}