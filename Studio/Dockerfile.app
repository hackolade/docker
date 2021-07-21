# Base image
FROM hackolade/studio:latest@sha256:8029f483e8e107fa7284ff9c49ed1da1ec6874e288c31f1557d81006fa5c5af9

# Environment variables
ENV USERNAME=hackolade
ENV UID=1000
ENV GID=1000
# the latest version of Hackolade will be downloaded.  If you need a specific version, 
# replace /current/ with /previous/v5.1.0/ for example or whatever version number you require
# Note that the application is onky certified to run in Docker for version 5.1.0 (and above) when adjustments were made for this purpose.
ENV HACKOLADE_URL "https://s3-eu-west-1.amazonaws.com/hackolade/current/Hackolade-linux-x64.zip"
#required
ENV DISPLAY ":99" 

WORKDIR $HOME

# The following instructions should be completed with root permissions
USER root

# Installation of application
RUN curl $HACKOLADE_URL -o $HOME/hackolade.zip -s \
	&& unzip $HOME/hackolade.zip \
	&& rm -f $HOME/hackolade.zip \
	&& chown $UID:$GID -R $HOME/Hackolade-linux-x64 \
	&& chown root:root $HOME/Hackolade-linux-x64/chrome-sandbox \
	&& chmod 4755 $HOME/Hackolade-linux-x64/chrome-sandbox \
	&& ln -s $HOME/Hackolade-linux-x64/Hackolade /usr/bin/hackolade \
	&& mkdir $HOME/Documents \
	&& chown $UID:$GID $HOME/Documents

# initiate image in order to be able to validate license
RUN init.sh

USER $USERNAME

#
# Plugin installation
#
# To find more plugins please check the plugin registry:
# https://github.com/hackolade/plugins/blob/master/pluginRegistry.json
#
# Uncomment lines below to select plugins to install in the image
#
# RUN installPlugin.sh Avro
# RUN installPlugin.sh Cassandra
# RUN installPlugin.sh CosmosDB-with-SQL-API
# RUN installPlugin.sh CosmosDB-with-Mongo-API
# RUN installPlugin.sh CosmosDB-with-Gremlin-API
# RUN installPlugin.sh DeltaLake
# RUN installPlugin.sh Elasticsearch
# RUN installPlugin.sh ElasticsearchV7plus
# RUN installPlugin.sh EventBridge
# RUN installPlugin.sh Firebase
# RUN installPlugin.sh Firestore
# RUN installPlugin.sh Glue
# RUN installPlugin.sh HBase
# RUN installPlugin.sh Hive
# RUN installPlugin.sh JanusGraph
# RUN installPlugin.sh Joi
# RUN installPlugin.sh Neptune-Gremlin
# RUN installPlugin.sh MariaDB
# RUN installPlugin.sh MarkLogic
# RUN installPlugin.sh MonStor
# RUN installPlugin.sh SQLServer
# RUN installPlugin.sh Neo4j
# RUN installPlugin.sh OpenAPI
# RUN installPlugin.sh Parquet
# RUN installPlugin.sh Redshift
# RUN installPlugin.sh ScyllaDB
# RUN installPlugin.sh Snowflake
# RUN installPlugin.sh Swagger
# RUN installPlugin.sh Synapse
# RUN installPlugin.sh TinkerPop
#

#
# Some programs needed for installation the application and plugins are not required at the runtime.
# To remove them please uncomment lines below:
#
# Notice: if you don't use JKS certificates you can also remove "openjdk-8-jdk"

# USER root
# RUN apt-get remove curl unzip zip nodejs -y
# USER $USERNAME
#

ENTRYPOINT ["startup.sh"]
CMD ["hackolade"]
