pipeline {
    agent any
    
    environment{
        KUBE_CREDENTIAL_ID = 'k8s'
    }
    
    stages{
        stage('version'){
            steps{
                withKubeConfig([credentialsId: "${KUBE_CREDENTIAL_ID}"]) {
                sh '''
                kubectl version --client -o yaml
                sleep 10
                kubectl get nodes 
                sleep 10
                kubectl delete pod nginx --ignore-not-found
                sleep 10
                kubectl run nginx --image=nginx 
                sleep 10
                kubectl delete svc nginx --ignore-not-found
                sleep 10
                kubectl expose pod nginx --type=NodePort --port=80 || true
                sleep 3
                kubectl get pods nginx -o wide
                sleep 5
                kubectl delete deploy nginx1 --ignore-not-found
                sleep 5
                kubectl create deploy nginx1 --image=nginx 
                sleep 5
                kubectl delete svc nginx1 --ignore-not-found
                sleep 10
                kubectl expose deploy nginx1 --type=NodePort --port=80 || true
                sleep 5
                kubectl get deploy nginx1 -o wide
                sleep 5
                kubectl get events --sort-by=.lastTimestamp
                sleep 5
                
                '''
            }}
        }
    }
}
