FROM node:18-alpine
RUN mkdir -p /opt/app
WORKDIR /opt/app
COPY . .
EXPOSE 8080
CMD [ "node", "dist/app.js" ]
