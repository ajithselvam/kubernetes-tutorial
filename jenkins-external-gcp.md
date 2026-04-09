Setting up Jenkins on Google Kubernetes Engine (GKE) using an external LoadBalancer is a solid way to get up and running quickly. Since you don't have a domain name, Kubernetes will provision a static regional IP address for you automatically.

1. Deployment Configuration (deploy.yaml)
This file defines the Jenkins pod. We use a StatefulSet (recommended over a standard Deployment) because Jenkins relies on its local filesystem (/var/jenkins_home) to store plugins, jobs, and configurations.

YAML
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: jenkins
  labels:
    app: jenkins
spec:
  serviceName: jenkins
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      containers:
      - name: jenkins
        image: jenkins/jenkins:lts
        ports:
          - containerPort: 8080
            name: http-port
          - containerPort: 50000
            name: agent-port
        env:
          - name: JAVA_OPTS
            value: "-Djenkins.install.runSetupWizard=true"
        resources:
          limits:
            memory: "2Gi"
            cpu: "1000m"
          requests:
            memory: "1Gi"
            cpu: "500m"
        volumeMounts:
          - name: jenkins-home
            mountPath: /var/jenkins_home
  volumeClaimTemplates:
  - metadata:
      name: jenkins-home
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 10Gi
2. Service Configuration (service.yaml)
This file exposes Jenkins to the internet. By setting the type to LoadBalancer, GCP will automatically provision a Cloud Load Balancer with an external IP address.

YAML
apiVersion: v1
kind: Service
metadata:
  name: jenkins-service
  annotations:
    # This tells GCP to create a regional external load balancer
    networking.gke.io/load-balancer-type: "External"
spec:
  type: LoadBalancer
  selector:
    app: jenkins
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 8080
    - name: agent
      protocol: TCP
      port: 50000
      targetPort: 50000
Quick Deployment Steps
Connect to your cluster: Ensure your gcloud and kubectl context is set to your GKE cluster.

Apply the files:

Bash
kubectl apply -f deploy.yaml
kubectl apply -f service.yaml
Get your IP:
Wait a minute or two for GCP to provision the IP, then run:

Bash
kubectl get svc jenkins-service
Look for the EXTERNAL-IP column. You can then access Jenkins at http://<EXTERNAL-IP>.

Retrieve Initial Admin Password:
Since you'll need the password to unlock Jenkins:

Bash
kubectl exec -it jenkins-0 -- cat /var/jenkins_home/secrets/initialAdminPassword
[!TIP]
A note on security: Because this uses a public LoadBalancer IP without a firewall or IAP (Identity-Aware Proxy), your Jenkins instance is open to the world. Make sure to complete the "Setup Wizard" immediately to create an admin user and secure the instance.
