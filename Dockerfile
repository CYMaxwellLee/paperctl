# Dockerfile -- Reproducible LaTeX build environment for paperctl
#
# Usage:
#   # Build image
#   docker build -t paperctl .
#
#   # Compile all papers (mount your conference directory)
#   docker run --rm -v ~/Project/Papers/eccv2026:/workspace paperctl compile
#
#   # Interactive shell
#   docker run --rm -it -v ~/Project/Papers/eccv2026:/workspace paperctl bash
#
#   # Single paper
#   docker run --rm -v ~/Project/Papers/eccv2026:/workspace paperctl compile --paper ewm

FROM texlive/texlive:latest

LABEL maintainer="ElsaLab NTHU"
LABEL description="paperctl: Conference paper management with full TeX Live"

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      git \
      jq \
      poppler-utils \
      python3 \
      curl \
      ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install paperctl
COPY paperctl /opt/paperctl/paperctl
COPY paperctl.d/ /opt/paperctl/paperctl.d/
RUN chmod +x /opt/paperctl/paperctl && \
    ln -sf /opt/paperctl/paperctl /usr/local/bin/paperctl

# Working directory is the mounted conference dir
WORKDIR /workspace

# Default: show help
ENTRYPOINT ["paperctl"]
CMD ["help"]
