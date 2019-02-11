FROM gcr.io/cloud-builders/kubectl

RUN apt-get update -y && \
    apt-get install -y curl gnupg && \
    curl -Lso /bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/linux/amd64/aws-iam-authenticator && \
    chmod +x /bin/aws-iam-authenticator && \
    rm -rf /var/lib/apt/lists/*

COPY "entrypoint.sh" "/entrypoint.sh"
RUN chmod +x /entrypoint.sh

#ENV KUBERNETES_MASTER=http://10.100.0.1:8080

ENTRYPOINT ["/entrypoint.sh"]
CMD ["help"]
