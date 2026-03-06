# Node Alpine -- multi-arch (amd64 + arm64)
# dist/ is pre-built locally and committed; Docker just serves it.
FROM node:lts-alpine

WORKDIR /app

# Copy package files first for caching
COPY package.json package-lock.json ./

# Install dependencies (skip native build scripts -- only vite preview is needed)
RUN npm ci --ignore-scripts

# Copy vite config files (needed for the preview server + auth gate middleware)
COPY vite.config.js vite-plugin-auth-gate.js ./

# Copy the pre-built app
COPY dist/ ./dist/

# Expose Vite preview port
EXPOSE 4173

# Serve the pre-built app
CMD ["node", "node_modules/.bin/vite", "preview", "--host", "0.0.0.0"]
