# ใช้ Node 20 (Alpine)
FROM node:20-alpine

# 1. ลง Git
RUN apk add --no-cache git

WORKDIR /app

# 2. Clone (URL เดิมของคุณ)
RUN rm -rf ./* && \
    git clone -b main https://chun3699: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@github.com/chun3699/PaaS-Frontend.git .

# 3. ติดตั้ง Library
RUN npm install

# 4. สร้าง Production Build
RUN npm run build

# 5. 🔥 แก้กลับเป็น 3000 (Port ภายใน)
EXPOSE 3000

# 6. 🔥 แก้กลับเป็น 3000 (เพื่อให้ตรงกับที่ Docker Compose Map เข้ามา)
ENV HOST=0.0.0.0
ENV PORT=3000
ENV NITRO_PORT=3000

# 7. สั่งรัน Server
CMD ["node", ".output/server/index.mjs"]