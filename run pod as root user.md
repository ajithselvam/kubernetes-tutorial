To run a pod as root in Kubernetes, you set runAsUser: 0 in the security context.

Option 1 — Pod-level (applies to all containers)
yamlapiVersion: v1
kind: Pod
metadata:
  name: root-pod
spec:
  securityContext:
    runAsUser: 0        # root
    runAsGroup: 0
  containers:
    - name: app
      image: your-image

Option 2 — Container-level (overrides pod-level)
yamlspec:
  containers:
    - name: app
      image: your-image
      securityContext:
        runAsUser: 0
        runAsNonRoot: false   # must explicitly set this if your image has ENTRYPOINT checks

Option 3 — If PodSecurityAdmission (PSA) is blocking you
Namespaces with restricted or baseline policies will reject root pods. You can label the namespace to allow it:
bashkubectl label namespace <your-ns> \
  pod-security.kubernetes.io/enforce=privileged
Or add a per-pod annotation to bypass PSA warnings:
yamlmetadata:
  annotations:
    pod-security.kubernetes.io/enforce: privileged

Verify it's running as root
bashkubectl exec -it root-pod -- whoami
# root

kubectl exec -it root-pod -- id
# uid=0(root) gid=0(root)

Quick tip: If you're on OpenShift, it also requires an explicit SCC grant:
bashoc adm policy add-scc-to-user anyuid -z <serviceaccount> -n <namespace>now how to login7:23 PMTo exec into a running pod:
Basic login
bashkubectl exec -it <pod-name> -- /bin/bash
If bash isn't available, try sh:
bashkubectl exec -it <pod-name> -- /bin/sh

Specify a container (multi-container pods)
bashkubectl exec -it <pod-name> -c <container-name> -- /bin/bash

Specify a namespace
bashkubectl exec -it <pod-name> -n <namespace> -- /bin/bash

Useful combos
bash# Get pod name first, then exec
kubectl get pods -n <namespace>
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash

# Run a one-off command without interactive shell
kubectl exec <pod-name> -- whoami
kubectl exec <pod-name> -- cat /etc/passwd

Quick tip: If the pod keeps crashing (CrashLoopBackOff), you can't exec into it normally. Override the entrypoint to keep it alive first:
bashkubectl run debug-pod --image=your-image -it --rm \
  --command -- /bin/shas root user7:23 PMJust add --user 0 flag... but that's actually a docker flag, not kubectl. In Kubernetes you do it via the security context (already set above). Here's the full picture:
If you set runAsUser: 0 in the pod spec (previous step)
Just exec normally — you're already root:
bashkubectl exec -it <pod-name> -- /bin/bash
# you'll land as root automatically

Override at exec-time (no spec change needed)
kubectl exec doesn't have a --user flag. Workaround:
bash# If nsenter is available on the node
kubectl exec -it <pod-name> -- nsenter -t 1 -m -u -i -n /bin/bash

# Or run su inside the shell
kubectl exec -it <pod-name> -- /bin/bash
su - root

Easiest approach — patch the running pod's security context
bashkubectl patch pod <pod-name> -p \
  '{"spec":{"containers":[{"name":"<container-name>","securityContext":{"runAsUser":0}}]}}'

Note: most fields in a running pod spec are immutable — you may need to delete and recreate the pod after patching the Deployment/StatefulSet instead.


Cleanest way — patch the Deployment
bashkubectl patch deployment <deploy-name> -p \
  '{"spec":{"template":{"spec":{"securityContext":{"runAsUser":0}}}}}'
This triggers a rollout and all new pods will exec in as root.
