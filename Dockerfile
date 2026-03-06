# Single-process Node.js static server — no npm install, no child processes
# Works in restricted Docker environments (Proxmox LXC)
FROM node:lts-alpine

WORKDIR /app

COPY server.js ./
COPY dist/ ./dist/

EXPOSE 4173

CMD ["node", "server.js"]
