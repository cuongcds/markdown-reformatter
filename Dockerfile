FROM node:20-alpine

WORKDIR /app

COPY package.json ./
RUN npm install --omit=dev

COPY .markdownlint-cli2.jsonc ./
COPY entrypoint.sh ./
RUN chmod +x ./entrypoint.sh

# Mount the local markdown folder to /data at `docker run` time.
VOLUME ["/data"]
WORKDIR /data

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["**/*.md"]
