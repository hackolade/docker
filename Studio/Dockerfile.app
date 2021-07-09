# Base image
FROM hackolade/studio:0.0.2

# Environment variables
ENV USERNAME=hackolade
ENV UID=1000
ENV GID=1000
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
# RUN installPlugin.sh Cassandra
# RUN installPlugin.sh Avro
#

ENTRYPOINT ["startup.sh"]
CMD ["hackolade"]
