# ---- Stage 1: Build ----
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install --only=production

# ---- Stage 2: Run ----
FROM node:18-alpine AS runner
WORKDIR /app

# Create non-root user (security best practice for fintech!)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=builder /app/node_modules ./node_modules
COPY index.js .

USER appuser

EXPOSE 3000
ENV APP_VERSION=v1

CMD ["node", "index.js"]