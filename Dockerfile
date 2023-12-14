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
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable" >> /etc/apt/sources.list.d/additional-repositories.list \
    && apt-get update

# Install Docker, kubeadm, kubelet, and kubectl
RUN apt-get -y install docker-ce kubectl

# Mark kubelet and kubectl to hold updates
RUN apt-mark hold kubectl

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
