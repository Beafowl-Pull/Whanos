# Running your own whanos instance
There is to way to create and manage your own whanos instance:

- Using [docker](#docker)
    - [Requirements](#requirements)
    - [Cloning the repository](#cloning-the-repository)
    - [Running the project](#running-the-project)
    - [Conclusion](#conclusion)
- Using [helm](#helm)
    - [Requirements](#requirements-1)
    - [Cloning the repository](#cloning-the-repository-1)
    - [Running the project](#running-the-project-1)
    - [Conclusion](#conclusion-1)

## Docker
### Requirements
- Docker
- Docker-compose
- Git

### Cloning the repository
```bash
git clone git@github.com:Beafowl-Pull/Whanos.git
cd Whanos
```

now that the repository is cloned, you need to create a `.env` file in the root of the project with the following content:
```bash
JENKINS_ADMIN_PASSWORD, #it will be the password for the admin user
JENKINS_DOCKER_REGISTRY, #it will be the base URL for docker push (e.g., for GCloud Artifact Registry : europe-west1-docker.pkg.dev/your-project-id)
```

### Running the project
```bash
docker-compose up --build
```

### Conclusion
Your whanos instance is now running on `http://localhost:8080` and you can login with the admin user and the password you set in the `.env` file.

## Helm
### Requirements
- Helm
- kubectl
- Having a load balancer available (e.g., GCloud Load Balancer)

### Cloning the repository
```bash
git clone git@github.com:Beafowl-Pull/Whanos.git
cd Whanos
```

now that the repository is cloned, you need to fill the `value.yaml` file in the `helm/Whanos` folder:
```yaml
whanos:
  jenkins:
    # the repository to pull the jenkins image created by docker build . (at the root of the repo)
    image: 
    # the password has to be encoded in base64
    adminpassword: 
  docker:
    # this is the docker registry base url
    registry:
    # by default another pod is running using dind
    host: tcp://dind-service:2375
```

### Running the project
```bash
helm install whanos helm/Whanos -f my_config.yaml
```

### Conclusion
Your whanos instance is now running on `http://<your-load-balancer-ip>:8080`.