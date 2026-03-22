Option 1 — ngrok (fastest, zero config)
Expose your NodePort instantly via a public tunnel:
bash# Install ngrok
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
sudo apt update && sudo apt install ngrok

# Authenticate (free account at ngrok.com)
ngrok authtoken <your-token>

# Expose your NodePort
ngrok http 30080
You'll get a public URL like https://abc123.ngrok.io — shareable instantly.

Option 2 — kubectl port-forward (local access only)
If you just need to test from your own machine:
bashkubectl port-forward service/my-service 8080:30080
Access at http://localhost:8080

Option 3 — Cloudflare Tunnel (free, permanent URL)
Better than ngrok for long-term use — no expiring URLs:
bash# Install cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# Login and create tunnel
cloudflared tunnel login
cloudflared tunnel create my-k8s-tunnel

# Run tunnel pointing to your NodePort
cloudflared tunnel --url http://localhost:30080
You get a permanent https://xxx.trycloudflare.com URL for free.

Option 4 — MetalLB (if self-hosted cluster)
If your cluster is on a local/on-prem machine, install MetalLB to get a LoadBalancer type working without a cloud provider:
bashkubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
Then configure an IP pool from your local network range and change your service type to LoadBalancer.

Quick recommendation:
SituationUseJust testing right nowkubectl port-forwardShare with others temporarilyngrokPermanent public accessCloudflare TunnelSelf-hosted clusterMetalLB
