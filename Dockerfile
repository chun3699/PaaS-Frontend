#อัพด้วย Portainer
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


# #อัพด้วย Filezilla
# # ใช้ Node 20 (Alpine)
# FROM node:20-alpine

# # สร้างโฟลเดอร์ทำงานใน Container
# WORKDIR /app

# # 1. ก๊อปปี้ไฟล์ package.json มาก่อนเพื่อติดตั้ง Library
# COPY package*.json ./

# # 2. ติดตั้ง Library
# RUN npm install

# # 3. ก๊อปปี้ไฟล์โค้ดทั้งหมด (ที่คุณลากผ่าน FileZilla) เข้ามาใน Container
# COPY . .

# # 4. สร้าง Production Build (Nuxt 3)
# RUN npm run build

# # 5. แก้กลับเป็น 3000 (Port ภายใน)
# EXPOSE 3000

# # 6. ตั้งค่า Environment (เพื่อให้ตรงกับที่ Docker Compose Map เข้ามา)
# ENV HOST=0.0.0.0
# ENV PORT=3000
# ENV NITRO_PORT=3000

# # 7. สั่งรัน Server
# CMD ["node", ".output/server/index.mjs"]