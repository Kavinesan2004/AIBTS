package com.mycompany.aibits;

import org.apache.catalina.startup.Tomcat;
import java.io.File;

public class Server {
    public static void main(String[] args) throws Exception {

        String port = System.getenv("PORT");
        if (port == null) port = "8080";

        Tomcat tomcat = new Tomcat();
        tomcat.setPort(Integer.parseInt(port));

        tomcat.getConnector();

        String webappDir = "src/main/webapp";
        tomcat.addWebapp("", new File(webappDir).getAbsolutePath());

        tomcat.start();
        tomcat.getServer().await();
    }
}
