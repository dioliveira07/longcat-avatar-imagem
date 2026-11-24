# Máquina de render Remotion (vídeos da agência). Só dependências; o projeto (src/ + public/) chega por rsync na hora.
FROM node:22-bookworm
RUN apt-get update -qq && apt-get install -y -qq ffmpeg rsync openssh-server fonts-inter fonts-liberation fonts-noto-color-emoji \
    libnss3 libdbus-1-3 libatk1.0-0 libatk-bridge2.0-0 libgbm1 libasound2 libxrandr2 libxkbcommon0 libxfixes3 libxcomposite1 \
    libxdamage1 libpango-1.0-0 libcairo2 libcups2 libdrm2 libegl1 libgles2 libvulkan1 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --legacy-peer-deps --no-audit --no-fund && npx remotion browser ensure
