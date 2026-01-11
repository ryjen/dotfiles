FROM golang:1.24-alpine

# Install git so go run can fetch remote modules
RUN apk add --no-cache git

# Working directory (not required but tidy)
WORKDIR /app

# Default entrypoint runs any Go module dynamically
ENTRYPOINT ["go", "run"]
