FROM node:24-bookworm-slim
ENV NODE_ENV=production HOST=0.0.0.0 PORT=4173
WORKDIR /app
COPY --chown=node:node package.json server.js ./
COPY --chown=node:node public ./public
USER node
EXPOSE 4173
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s CMD node -e "fetch('http://127.0.0.1:4173/api/health').then(r=>{if(!r.ok)process.exit(1)}).catch(()=>process.exit(1))"
CMD ["node","server.js"]
