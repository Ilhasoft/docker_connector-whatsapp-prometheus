# pull official base image
FROM python:3-slim-buster AS base

ARG APP_UID=1000
ARG APP_GID=500

ARG APP_PORT=8080

ARG BUILD_DEPS="\
  python3-dev build-essential \
  build-essential"
ARG RUNTIME_DEPS="\
  tzdata \
  netcat \
  curl \
  gosu \
  bash"

ARG VERSION="0.1"

# set environment variables
ENV VERSION=${VERSION} \
  RUNTIME_DEPS=${RUNTIME_DEPS} \
  BUILD_DEPS=${BUILD_DEPS} \
  PYTHONDONTWRITEBYTECODE=1 \
  PYTHONUNBUFFERED=1 \
  PYTHONIOENCODING=UTF-8 \
  PIP_DISABLE_PIP_VERSION_CHECK=1 \
  APP_PORT="${APP_PORT}" \
  PATH="/install/bin:${PATH}"

LABEL version=${VERSION} \
  os="debian" \
  os.version="10" \
  name="APP ${VERSION}" \
  description="APP image" \
  maintainer="APP Team"

RUN addgroup --gid "${APP_GID}" app_group \
  && useradd --system -m -d /app -u "${APP_UID}" -g "${APP_GID}" app_user

# set work directory
WORKDIR /app

FROM base AS build

RUN if [ ! "x${BUILD_DEPS}" = "x" ] ; then apt-get update \
  && apt-get install -y --no-install-recommends ${BUILD_DEPS} ; fi

# install dependencies
#RUN pip install --upgrade pip
COPY requirements.txt requirements-freeze.tx[t] .
RUN mkdir /install \
  && if test -e requirements-freeze.txt; then pip install --no-cache-dir --prefix=/install -r requirements-freeze.txt ; else pip install --no-cache-dir --prefix=/install -r requirements.txt ; fi

# copy project
#COPY . .

FROM base

COPY --from=build /install /usr/local

RUN apt-get update \
  && SUDO_FORCE_REMOVE=yes apt-get remove --purge -y ${BUILD_DEPS} \
  && apt-get autoremove -y \
  && apt-get install -y --no-install-recommends ${RUNTIME_DEPS} \
  && rm -rf /usr/share/man \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY --chown=app_user:app_group . .
COPY --chown=root:root docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["start"]
#CMD sleep 6d

HEALTHCHECK --interval=15s --timeout=20s --start-period=60s \
  CMD /docker-entrypoint.sh healthcheck

