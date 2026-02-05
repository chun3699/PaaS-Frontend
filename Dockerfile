# ใช้ Node 20 (Alpine)
FROM node:20-alpine

# 1. ลง Git
RUN apk add --no-cache git

WORKDIR /app

# 2. 🔥 แก้ไขตรงนี้:
# - ลบ #main ออกจาก URL
# - เพิ่ม -b main ไว้ข้างหน้า เพื่อระบุ Branch
# - อย่าลืมจุด . ข้างหลังสุด (บอกให้ลงใน folder ปัจจุบัน)
RUN rm -rf ./* && \
    git clone -b main https://chun3699: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@github.com/chun3699/PaaS-Frontend.git .

# 3. ติดตั้ง Library
RUN npm install

# 4. สร้าง Production Build
RUN npm run build

# 5. เปิด Port 3001
EXPOSE 3001

# 6. ตั้งค่า Environment
ENV HOST=0.0.0.0
ENV PORT=3001
ENV NITRO_PORT=3001

# 7. สั่งรัน Server
CMD ["node", ".output/server/index.mjs"]