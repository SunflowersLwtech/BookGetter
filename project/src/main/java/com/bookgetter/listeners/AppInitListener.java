package com.bookgetter.listeners;

import com.bookgetter.utils.FileUtil;
import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;

/**
 * Application lifecycle listener that initializes FileUtil with the correct webapp path.
 */
@WebListener
public class AppInitListener implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        // Get the real path of the web application
        String webAppPath = sce.getServletContext().getRealPath("");
        
        // Initialize FileUtil with the webapp path
        FileUtil.init(webAppPath);
        
        System.out.println("[BookGetter] Application initialized");
        System.out.println("[BookGetter] Data directory: " + FileUtil.getDataDirPath());
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        System.out.println("[BookGetter] Application shutting down");
    }
}
