FROM registry.pfa.fr.corp:5000/crony2/mcu
LABEL description="Dockerfile to build mcu-coverity image"
LABEL maintainer="benoit.vignali@forvia.com"

# Download and configure Coverity
ARG COVERITY_VERSION="cov-analysis-linux64-2021.06"
ARG COVERITY_DEST="/opt/coverity"
ARG COVERITY_LICENSE="license-20230412"
ENV COVERITY_PATH=${COVERITY_DEST}/${COVERITY_VERSION}

RUN mkdir ${COVERITY_DEST} \
    && wget --no-check-certificate -q https://coverity.pfa.fr.corp/downloads/${COVERITY_VERSION}.tar.gz -O - | tar xzC ${COVERITY_DEST} \
    && wget --no-check-certificate -q https://coverity.pfa.fr.corp/downloads/${COVERITY_LICENSE}.dat \
    && mv ${COVERITY_LICENSE}.dat ${COVERITY_PATH}/bin

RUN ${COVERITY_PATH}/bin/cov-configure --compiler arm-none-eabi-gcc --comptype gcc --template \
    && ${COVERITY_PATH}/bin/cov-configure --compiler arm-none-eabi-g++ --comptype g++ --template
