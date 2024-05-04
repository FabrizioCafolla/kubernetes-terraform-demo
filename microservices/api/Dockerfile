FROM node:18-alpine

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 8080

HEALTHCHECK CMD curl --fail http://localhost:8080/health || exit 1

RUN adduser -D test && \
    chown -R test /usr/src/app

USER test

CMD [ "node", "app.js" ]
