# ใช้ Node 20 (Alpine)
FROM node:20-alpine

# 1. ลง Git (จำเป็นมากสำหรับสูตรอาจารย์)
RUN apk add --no-cache git

WORKDIR /app

# 2. 🔥 สูตรอาจารย์: สั่ง Clone โค้ดลงมาเอง
# ⚠️ เปลี่ยน TOKEN, USER, REPO ให้เป็นของ Frontend คุณ
RUN rm -rf ./* && \
    git clone https://chun3699:YOUR_GITHUB_TOKEN@github.com/chun3699/YOUR_FRONTEND_REPO.git .

# 3. ติดตั้ง Library
RUN npm install

# 4. สร้าง Production Build (Nuxt จะสร้างโฟลเดอร์ .output)
RUN npm run build

# 5. เปิด Port 3001 (หนี Port 3000)
EXPOSE 3001

# 6. ตั้งค่า Host และ Port สำหรับ Nuxt 3 (Nitro Engine)
# Nuxt 3 Production ใช้ตัวแปร PORT หรือ NITRO_PORT
ENV HOST=0.0.0.0
ENV PORT=3001
ENV NITRO_PORT=3001

# 7. สั่งรัน Server (Nuxt 3 รันด้วยไฟล์นี้)
CMD ["node", ".output/server/index.mjs"]