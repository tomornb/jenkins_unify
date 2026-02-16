FROM jenkins/jenkins:2.550

ENV DEBIAN_FRONTEND=noninteractive

USER root

# Workaround for Post-Invoke failures (if your Docker host is old)
RUN rm -f /etc/apt/apt.conf.d/docker-clean \
          /etc/apt/apt.conf.d/99docker-clean \
          /etc/apt/apt.conf.d/99docker || true

# Base tools
RUN apt-get update -y && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Docker repo key (modern method)
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
      > /etc/apt/sources.list.d/docker.list

# Install Docker CLI + Compose v2 plugin (not docker engine)
RUN apt-get update -y && apt-get install -y --no-install-recommends \
      docker-ce-cli docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Create user + docker group access
RUN set -eux; \
    # สร้าง user (ถ้ายังไม่มี)
    id -u omropr >/dev/null 2>&1 || useradd -m -u 51011 omropr; \
    \
    # สร้าง group docker ถ้ายังไม่มี (กำหนด GID 495 ถ้ายังว่าง)
    if ! getent group docker >/dev/null; then \
      if getent group 495 >/dev/null; then \
        groupadd docker; \
      else \
        groupadd -g 495 docker; \
      fi; \
    fi; \
    \
    # เพิ่ม jenkins + omropr เข้า group docker
    usermod -aG docker jenkins; \
    usermod -aG docker omropr; \
    \
    # ปรับ owner โฟลเดอร์ Jenkins home
    chown -R omropr:omropr "$JENKINS_HOME"

USER omropr
