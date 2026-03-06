# Node Alpine -- multi-arch (amd64 + arm64)
FROM node:lts-alpine

WORKDIR /app

# Install system dependencies required for Bun and Neutralino
RUN apk add --no-cache wget curl bash
RUN apk add --no-cache python3 make g++ && ln -sf python3 /usr/bin/python

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash

# Add Bun to PATH so it can be used in subsequent steps
ENV PATH="/root/.bun/bin:${PATH}"

# Copy package files first for caching
COPY package.json package-lock.json ./

# Install dependencies, skip native build scripts (bufferutil/utf-8-validate
# are optional ws performance addons; esbuild binary is fixed below)
RUN npm ci --ignore-scripts

# Make esbuild binary executable (npm ci doesn't preserve execute bits)
RUN find node_modules -path "*/@esbuild/*/bin/esbuild" -exec chmod +x {} \; 2>/dev/null || true

# Copy the rest of the project
COPY . .

# Build the project (Bun is now available for "bun x neu build")
RUN bun run build

# Expose Vite preview port
EXPOSE 4173

# Run the built project
CMD ["bun", "run", "preview", "--", "--host", "0.0.0.0"]
