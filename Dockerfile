# Use nginx to serve pre-built static files — no Node.js, no esbuild
FROM nginx:alpine

# Copy pre-built app
COPY dist/ /usr/share/nginx/html/

# Nginx config with /health endpoint and SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 4173

CMD ["nginx", "-g", "daemon off;"]
