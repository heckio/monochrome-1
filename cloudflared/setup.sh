#!/usr/bin/env bash
# Cloudflare Tunnel setup for Monochrome
# Run as root on your Proxmox host: bash cloudflared/setup.sh
set -e

TUNNEL_NAME="monochrome"
CONFIG_DIR="/etc/cloudflared"
CONFIG_FILE="$CONFIG_DIR/config.yml"

# ── 1. Install cloudflared ────────────────────────────────────────────────────
if ! command -v cloudflared &>/dev/null; then
    echo "Installing cloudflared..."
    curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
        -o /usr/local/bin/cloudflared
    chmod +x /usr/local/bin/cloudflared
    echo "cloudflared installed: $(cloudflared --version)"
else
    echo "cloudflared already installed: $(cloudflared --version)"
fi

# ── 2. Authenticate ───────────────────────────────────────────────────────────
echo ""
echo "Opening Cloudflare login... (a browser link will appear)"
cloudflared tunnel login

# ── 3. Create tunnel ─────────────────────────────────────────────────────────
echo ""
echo "Creating tunnel '$TUNNEL_NAME'..."
cloudflared tunnel create "$TUNNEL_NAME"

# Extract tunnel UUID
TUNNEL_ID=$(cloudflared tunnel list --output json | \
    python3 -c "import sys,json; tunnels=json.load(sys.stdin); \
    [print(t['id']) for t in tunnels if t['name']=='$TUNNEL_NAME']" 2>/dev/null || \
    cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')

if [ -z "$TUNNEL_ID" ]; then
    echo "ERROR: Could not determine tunnel ID. Check 'cloudflared tunnel list'."
    exit 1
fi

echo "Tunnel ID: $TUNNEL_ID"

# ── 4. Write config ───────────────────────────────────────────────────────────
mkdir -p "$CONFIG_DIR"

# Prompt for domain
echo ""
read -rp "Enter your domain (e.g. music.example.com): " DOMAIN

cat > "$CONFIG_FILE" <<EOF
tunnel: $TUNNEL_ID
credentials-file: /root/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: $DOMAIN
    service: http://localhost:3000
  - service: http_status:404
EOF

echo "Config written to $CONFIG_FILE"

# ── 5. Create DNS record ──────────────────────────────────────────────────────
echo ""
echo "Creating DNS CNAME for $DOMAIN..."
cloudflared tunnel route dns "$TUNNEL_NAME" "$DOMAIN"

# ── 6. Install as systemd service ────────────────────────────────────────────
echo ""
echo "Installing cloudflared as a systemd service..."
cloudflared service install

systemctl enable cloudflared
systemctl start cloudflared

echo ""
echo "Done! Tunnel status:"
systemctl status cloudflared --no-pager

echo ""
echo "Your app should be live at: https://$DOMAIN"
echo "To check tunnel health: cloudflared tunnel info $TUNNEL_NAME"
