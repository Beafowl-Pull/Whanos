FROM jenkins/jenkins:lts

USER root

# Update and install necessary packages
RUN apt-get update \
    && apt-get -y install \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg2 \
        software-properties-common

# Add Kubernetes signing key
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

# Add Kubernetes repository
RUN echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list

# Add Docker repository and key
RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

RUN echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

RUN apt-get update

RUN apt-get install -y kubelet kubeadm kubectl

RUN apt-mark hold kubelet kubeadm kubectl

RUN apt-get update
RUN apt-get install ca-certificates curl
RUN install -m 0755 -d /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
RUN chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update

# Install Docker, kubeadm, kubelet, and kubectl
RUN apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Additional setup for Jenkins and Docker
RUN usermod -aG docker jenkins \
    && curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Copy necessary files and set configurations for Jenkins
COPY helm/AutoDeploy /helm/AutoDeploy
COPY utils/config /root/.kube/config
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
COPY jenkins/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt
COPY images /images
COPY jenkins /jenkins
ENV CASC_JENKINS_CONFIG /jenkins/config.yml
