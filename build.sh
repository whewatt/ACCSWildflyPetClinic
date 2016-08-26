##!/bin/sh

WILDFLY_VERSION=10.0.0.Final
WILDFLY_RELEASE=wildfly-${WILDFLY_VERSION}
WILDFLY_ARCHIVE=${WILDFLY_RELEASE}.tar.gz
APP_ARCHIVE=wildfly-petclinic-dist.zip

# Clean up any artifacts left from previous builds
rm -rf ${WILDFLY_RELEASE}
rm -rf ${APP_ARCHIVE}
rm manifest.json

if [ -n "$HTTP_PROXY" ]; then
  PROXY_ARG="--proxy ${HTTP_PROXY}"
fi

# Download WILDFLY distribution if necessary
if [ ! -r ${WILDFLY_ARCHIVE} ]; then
  curl -X GET \
     ${PROXY_ARG} \
     -o ${WILDFLY_ARCHIVE} \
     http://download.jboss.org/wildfly/${WILDFLY_VERSION}/${WILDFLY_ARCHIVE}
fi


# Unzip WILDFLY distribution
tar -xf ${WILDFLY_ARCHIVE}
# Strip out unnecessary components
rm -rf ${WILDFLY_RELEASE}/docs
rm -rf ${WILDFLY_RELEASE}/welcome-content
rm -rf ${WILDFLY_RELEASE}/app-client


# build Petclinic

# Download Spring Petclinic if necessary
if [ ! -r spring-petclinic ]; then
  git clone https://github.com/spring-projects/spring-petclinic.git
fi

# Install jboss-web.xml so petclinic is in root context
cp -f jboss-web.xml spring-petclinic/src/main/webapp/WEB-INF/.

# Build Petclinic
cd spring-petclinic
mvn clean package
cd ..

# Move petclinic.war to WILDFLY webapps folder
mv spring-petclinic/target/petclinic.war ${WILDFLY_RELEASE}/standalone/deployments/.

# Update JBoss release name in manifest
sed "s|WILDFLY_RELEASE|${WILDFLY_RELEASE}|g" manifest.template > manifest.json

# Create application archive with WILDFLY (with petclinic war) and manifest.json
zip -r ${APP_ARCHIVE} manifest.json ${WILDFLY_RELEASE}

# Remove the expanded WILDFLY distribution
rm -rf ${WILDFLY_RELEASE}
