FROM ubuntu:20.04

# This is the release of Vault to pull in.
ARG VAULT_VERSION=1.10.5+ent.hsm

# Create a vault user and group first so the IDs get set the same way,
# even as the rest of this may change over time.
RUN groupadd vault && \
    useradd -g vault vault

# Set up certificates, our base tools, and Vault.
RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get install -y wget ca-certificates unzip && \
    mkdir -p /tmp/build && \
    cd /tmp/build && \
    wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip && \
    wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS && \
    wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS.sig && \
    unzip -d /tmp/build vault_${VAULT_VERSION}_linux_amd64.zip && \
    cp /tmp/build/vault /bin/vault && \
    if [ -f /tmp/build/EULA.txt ]; then mkdir -p /usr/share/doc/vault; mv /tmp/build/EULA.txt /usr/share/doc/vault/EULA.txt; fi && \
    if [ -f /tmp/build/TermsOfEvaluation.txt ]; then mkdir -p /usr/share/doc/vault; mv /tmp/build/TermsOfEvaluation.txt /usr/share/doc/vault/TermsOfEvaluation.txt; fi && \
    cd /tmp && \
    rm -rf /tmp/build && \
    apt-get purge -y gnupg openssl && \
    rm -rf /root/.gnupg

# /vault/logs is made available to use as a location to store audit logs, if
# desired; /vault/file is made available to use as a location with the file
# storage backend, if desired; the server will be started with /vault/config as
# the configuration directory so you can add additional config files in that
# location.
RUN mkdir -p /vault/logs && \
    mkdir -p /vault/file && \
    mkdir -p /vault/config && \
    chown -R vault:vault /vault

# Expose the logs directory as a volume since there's potentially long-running
# state in there
VOLUME /vault/logs

# Expose the file directory as a volume since there's potentially long-running
# state in there
VOLUME /vault/file

# 8200/tcp is the primary interface that applications use to interact with
# Vault.
EXPOSE 8200

# The entry point script uses dumb-init as the top-level process to reap any
# zombie processes created by Vault sub-processes.
#
# For production derivatives of this container, you shoud add the IPC_LOCK
# capability so that Vault can mlock memory.
#
# COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
#COPY docker-entrypoint.sh /docker-entrypoint.sh
#ENTRYPOINT ["/docker-entrypoint.sh"]

# By default you'll get a single-node development server that stores everything
# in RAM and bootstraps itself. Don't use this configuration for production.
#CMD ["server", "-dev"]
