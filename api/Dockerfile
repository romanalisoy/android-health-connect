FROM node:23-alpine
WORKDIR /usr/app
COPY . .
RUN npm install
RUN npm run build
RUN npm install -g pm2
CMD pm2-runtime 'npm start'
EXPOSE 3000