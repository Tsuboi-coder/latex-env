FROM texlive/texlive:latest

RUN apt-get update && \
    apt-get install -y \
        fontconfig \
        python3 \
        python3-pygments \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work