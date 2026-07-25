This is a very common L2 DevOps/SRE production incident. The difference between an L1 and L2 engineer is that L2 doesn't just restart things—they find the root cause and restore service with minimal downtime.

Scenario

A GKE cluster node reaches 100% CPU/Memory.
Pods start restarting (CrashLoopBackOff, OOMKilled) and some applications become unavailable.

Step 1: Acknowledge the Incident

First, verify the cluster health.

kubectl get nodes
kubectl top nodes
kubectl get pods -A
kubectl top pods -A

Look for

Node at 95-100% CPU
Node at 95-100% Memory
Pods restarting
Pods in Pending state
Step 2: Find Which Node Is the Problem
kubectl top nodes

Example

NAME         CPU      MEMORY
gke-node-1   98%      99%
gke-node-2   22%      41%
gke-node-3   18%      37%

Immediately identify:

gke-node-1 is overloaded.

Step 3: Identify Which Pods Are Consuming Resources
kubectl top pods -A --sort-by=memory

or

kubectl top pods -A --sort-by=cpu

Example

payments-api        1800Mi
redis               1400Mi
analytics-worker    1200Mi

Now you know the culprit.

Step 4: Check Why Pods Restarted
kubectl describe pod <pod-name>

Look for

OOMKilled

or

Evicted

or

Back-off restarting failed container
Step 5: Check Events
kubectl get events --sort-by=.metadata.creationTimestamp

You may see

NodeHasMemoryPressure

Killing container

Evicted Pod

Insufficient memory

These events tell you exactly why Kubernetes took action.

Step 6: Check Logs
kubectl logs <pod>

If the pod already restarted

kubectl logs <pod> --previous

This is a very common L2 step.

Step 7: Immediate Recovery

Depending on the situation:

Option A — Scale Deployment

If traffic increased suddenly

kubectl scale deployment payment-api --replicas=6

Traffic gets distributed.

Option B — Restart Bad Pod
kubectl delete pod <pod-name>

Deployment recreates it.

Option C — Drain the Bad Node

If only one node is unhealthy

kubectl cordon gke-node-1

kubectl drain gke-node-1 --ignore-daemonsets

Pods move to healthy nodes.

Option D — Increase Node Pool Size

If the cluster is out of capacity

gcloud container clusters resize CLUSTER_NAME \
  --node-pool=default-pool \
  --num-nodes=5

Or rely on Cluster Autoscaler if enabled.

Step 8: Verify Recovery
kubectl get pods -A

kubectl top nodes

kubectl top pods

Check

CPU below 80%
Memory below 80%
No restarting pods
All pods Running
Root Cause Analysis (RCA)

As an L2 engineer, don't stop after recovery. Determine why it happened.

Possible causes include:

Sudden spike in user traffic
Memory leak in an application
CPU-intensive background jobs
Missing or incorrect resource requests/limits
Autoscaler disabled or slow to react
Too few nodes in the cluster
Large deployment rollout
Misconfigured Horizontal Pod Autoscaler (HPA)
Long-Term Fixes
Set proper resource requests and limits.
resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
  limits:
    cpu: "1"
    memory: "1Gi"
Enable or tune the Horizontal Pod Autoscaler (HPA).
Enable Cluster Autoscaler for node pools.
Use Pod Disruption Budgets to maintain availability during node maintenance.
Monitor with Prometheus/Grafana or SigNoz and configure alerts for:
CPU > 80%
Memory > 80%
Restart count increases
OOMKilled events
Investigate and fix application memory leaks or inefficient code.
How an L2 Engineer Would Communicate During the Incident

Incident: Payment API availability degraded due to node memory exhaustion on gke-node-1. Multiple pods entered OOMKilled and CrashLoopBackOff.
Actions taken: Identified the overloaded node using kubectl top nodes, verified OOMKilled events, scaled the deployment, and rescheduled workloads to healthy nodes.
Status: Service restored and all pods are healthy.
Root cause: High memory consumption combined with insufficient node capacity.
Next steps: Tune resource requests/limits, validate HPA behavior, and review autoscaling thresholds.

This is exactly the type of troubleshooting expected from an L2 DevOps/SRE engineer.

Since you're working as a DevOps Engineer and using GKE, Kubernetes, and SigNoz, practicing scenarios like this will closely match real production incidents and technical interviews.
