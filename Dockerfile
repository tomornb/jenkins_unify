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
RUN useradd -m -r -u 51011 omropr && \
    groupmod -g 495 docker || true && \
    usermod -aG docker jenkins && \
    usermod -aG docker omropr && \
    chown -R omropr:omropr "$JENKINS_HOME"

USER omropr
