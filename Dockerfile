FROM fredboat/lavalink:4.0.8

USER root

# Copy config yang kita buat tadi ke dalam folder Lavalink
COPY application.yml /opt/Lavalink/application.yml

# Batasi penggunaan Java Heap Memory maksimal 350MB agar sisa RAM Koyeb (512MB) aman
ENTRYPOINT ["java", "-Xmx350m", "-jar", "/opt/Lavalink/Lavalink.jar"]
