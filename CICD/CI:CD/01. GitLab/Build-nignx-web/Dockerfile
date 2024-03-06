FROM nginx
RUN apt-get update && apt-get install -y net-tools \ 
    iputils-ping \ 
    dnsutils \ 
    git \ 
    wget \
    && rm -rf /var/lib/apt/lists/*
COPY index.html /usr/share/nginx/html/index.html
