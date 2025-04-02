FROM hexletbasics/base-image:latest

# https://github.com/firstBitMarksistskaya/onec-docker/blob/feature/first-bit/oscript/Dockerfile

# Аргументы по умолчанию
ARG MONO_VERSION=6.12.0.122
ARG OVM_REPOSITORY_OWNER=oscript-library
ARG OVM_VERSION=v1.2.3
ARG ONESCRIPT_VERSION=stable
ARG ONESCRIPT_PACKAGES="add gitsync vanessa-runner stebi edt-ripper"

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    gnupg \
    dirmngr \
    wget \
  # Скачиваем и конвертируем GPG-ключ в подходящий формат
  && mkdir -p /etc/apt/keyrings \
  && wget -qO - https://download.mono-project.com/repo/xamarin.gpg | gpg --dearmor -o /etc/apt/keyrings/mono.gpg \
  # Добавляем репозиторий
  && echo "deb [signed-by=/etc/apt/keyrings/mono.gpg] https://download.mono-project.com/repo/debian stable main" > /etc/apt/sources.list.d/mono-official-stable.list \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    mono-runtime \
    ca-certificates-mono \
    libmono-i18n4.0-all \
    libmono-system-runtime-serialization4.0-cil \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/*

# Синхронизация сертификатов (иногда нужна для Mono)
RUN cert-sync --user /etc/ssl/certs/ca-certificates.crt || true

# Удаление устаревшего DST Root CA X3 сертификата
COPY ./scripts/remove-dst-root-ca-x3.sh /remove-dst-root-ca-x3.sh
RUN chmod +x /remove-dst-root-ca-x3.sh \
  && /remove-dst-root-ca-x3.sh \
  && rm /remove-dst-root-ca-x3.sh

# Установка ovm и onescript
RUN wget https://github.com/${OVM_REPOSITORY_OWNER}/ovm/releases/download/${OVM_VERSION}/ovm.exe \
  && mv ovm.exe /usr/local/bin/ \
  && echo 'mono /usr/local/bin/ovm.exe "$@"' > /usr/local/bin/ovm \
  && chmod +x /usr/local/bin/ovm \
  && ovm use --install ${ONESCRIPT_VERSION}

# Добавление oscript в PATH
ENV OSCRIPTBIN=/root/.local/share/ovm/current/bin
ENV PATH="$OSCRIPTBIN:$PATH"

# Установка oscript-пакетов
RUN opm install opm \
  && opm update --all \
  && opm install ${ONESCRIPT_PACKAGES} \
  && if echo "$ONESCRIPT_PACKAGES" | grep -q "gitsync"; then \
       gitsync plugins init \
       && gitsync plugins enable limit \
       && gitsync plugins disable limit; \
     fi

# Установка точки входа
# COPY ./oscript/docker-entrypoint.sh /
# RUN chmod +x /docker-entrypoint.sh
# ENTRYPOINT ["/docker-entrypoint.sh"]
