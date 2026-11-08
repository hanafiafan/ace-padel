# Multi-stage lightweight Node.js container for Ace Padel API
FROM node:20-alpine AS base

WORKDIR /app

# Install dependencies first for optimal Docker layer caching
COPY package*.json ./
RUN npm ci --only=production

# Copy application source
COPY src ./src

# Non-root user for security compliance
USER node

# Default port
EXPOSE 3001

ENV NODE_ENV=production
ENV PORT=3001

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3001/api/health || exit 1

CMD ["node", "src/index.js"]

