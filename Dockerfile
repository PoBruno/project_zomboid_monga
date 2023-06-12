###########################################################
# Dockerfile that builds a CSGO Gameserver
###########################################################
FROM cm2network/steamcmd:root

LABEL maintainer="brunoshy@gmail.com"

ENV STEAMAPPID 380870
ENV STEAMAPP pz
ENV STEAMAPPDIR "${HOMEDIR}/${STEAMAPP}-server"


# Install required packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
      dos2unix \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Download the Project Zomboid dedicated server app using the steamcmd app
# Set the entry point file permissions
RUN set -x \
  && mkdir -p "${STEAMAPPDIR}" \
  && chown -R "${USER}:${USER}" "${STEAMAPPDIR}" \
  && bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "${STEAMAPPDIR}" \
                                    +login anonymous \
                                    +app_update "${STEAMAPPID}" validate \
                                    +quit

# Copy the entry point file
COPY --chown=${USER}:${USER} scripts/entry.sh /server/scripts/entry.sh
RUN chmod 550 /server/scripts/entry.sh

# Create required folders to keep their permissions on mount
RUN mkdir -p "${HOMEDIR}/Zomboid"

WORKDIR ${HOMEDIR}
# Expose ports
EXPOSE 16261-16262/udp \
    27015/tcp \
    8766/tcp \
    8767/tcp \
    16261/tcp

ENTRYPOINT ["/server/scripts/entry.sh"]




FROM ubuntu:latest

RUN dpkg --add-architecture i386 && \
  apt-get update && \
  apt-get install -y lib32gcc1 curl && \
  useradd -m steam && \
  su steam -c "curl -sqL \"https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz\" | tar zxvf -" && \
  su steam -c "mkdir /home/steam/project-zomboid" && \
  su steam -c "/home/steam/steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/steam/project-zomboid +app_update 380870 validate +quit" && \
  su steam -c "echo \"cd /home/steam/project-zomboid\" > /home/steam/run.sh" && \
  su steam -c "echo \"./start-server.sh\" >> /home/steam/run.sh" && \
  su steam -c "chmod +x /home/steam/run.sh"

EXPOSE 8766/tcp 8767/tcp 16261/tcp
WORKDIR /home/steam
USER steam
CMD ["/bin/bash", "/home/steam/run.sh"]

#End of Dockerfile

