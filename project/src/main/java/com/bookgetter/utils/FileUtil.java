package com.bookgetter.utils;

import java.io.*;
import java.nio.file.*;

public class FileUtil {
    private static String dataDir = null;

    /**
     * Initialize the data directory path. Must be called once during application startup.
     * @param webAppPath The real path of the web application (from ServletContext.getRealPath(""))
     */
    public static void init(String webAppPath) {
        dataDir = webAppPath + File.separator + "data";
        try {
            Files.createDirectories(Paths.get(dataDir));
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    /**
     * Set data directory directly (for testing or alternative configurations)
     */
    public static void setDataDir(String path) {
        dataDir = path;
        try {
            Files.createDirectories(Paths.get(dataDir));
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private static String getDataDir() {
        if (dataDir == null) {
            // Fallback: use working directory /data
            dataDir = System.getProperty("user.dir") + File.separator + "data";
            try {
                Files.createDirectories(Paths.get(dataDir));
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        return dataDir;
    }

    public static String readFile(String filename) throws IOException {
        Path path = Paths.get(getDataDir(), filename);
        if (!Files.exists(path)) {
            return null;
        }
        return new String(Files.readAllBytes(path), "UTF-8");
    }

    public static void writeFile(String filename, String content) throws IOException {
        Path path = Paths.get(getDataDir(), filename);
        Files.write(path, content.getBytes("UTF-8"), StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
    }

    public static boolean fileExists(String filename) {
        return Files.exists(Paths.get(getDataDir(), filename));
    }

    public static String getDataDirPath() {
        return getDataDir();
    }
}
