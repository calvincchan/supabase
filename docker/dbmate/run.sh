docker build -t db-mate .
docker run -it --rm -v "$(pwd)":/app db-mate /bin/bash