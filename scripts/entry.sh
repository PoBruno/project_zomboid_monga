#!/bin/bash

cd ${STEAMAPPDIR}

# Forçar uma atualização se o ambiente estiver definido
if [ "${FORCEUPDATE}" == "1" ]; then
  echo "FORCEUPDATE variable is set, so the server will be updated right now"
  bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "${STEAMAPPDIR}" +login anonymous +app_update "${STEAMAPPID}" validate +quit
fi

# Processe os argumentos em variáveis
ARGS=""
#Defina a memória do servidor. As unidades são aceitas (1024m=1Gig, 2048m=2Gig, 4096m=4Gig): Exemplo: 1024m
if [ -n "${MEMORY}" ]; then
  ARGS="${ARGS} -Xmx${MEMORY} -Xms${MEMORY}"
fi

# Opção para executar um Soft Reset
if [ "${SOFTRESET}" == "1" ] || [ "${SOFTRESET,,}" == "true" ]; then
  ARGS="${ARGS} -Dsoftreset"
fi

# Fim dos argumentos Java
ARGS="${ARGS} -- "

# Desativa a integração do Steam no servidor.
# - Default: Enabled
if [ "${NOSTEAM}" == "1" ] || [ "${NOSTEAM,,}" == "true" ]; then
  ARGS="${ARGS} -nosteam"
fi

# Define o caminho para o diretório do cache de dados do jogo.
# - Default: ~/Zomboid
# - Example: /server/Zomboid/data
if [ -n "${CACHEDIR}" ]; then
  ARGS="${ARGS} -cachedir=${CACHEDIR}"
fi

# Opção para controlar de onde os mods são carregados e a ordem. Qualquer uma das 3 palavras-chave pode ser deixada de fora e pode aparecer em qualquer ordem.
# - Default: workshop,steam,mods
# - Example: mods,steam
if [ -n "${MODFOLDERS}" ]; then
  ARGS="${ARGS} -modfolders ${MODFOLDERS}"
fi

# Inicia o jogo no modo de depuração.
# - Default: Disabled
if [ "${DEBUG}" == "1" ] || [ "${DEBUG,,}" == "true" ]; then
  ARGS="${ARGS} -debug"
fi

# Opção para ignorar o prompt de digitação de senha ao criar um servidor.
# Esta opção é obrigatória na primeira inicialização ou será solicitada no console e a inicialização falhará.
# Uma vez iniciado e os dados criados, podem ser removidos sem problemas.
# É recomendável removê-lo, porque o servidor registra os argumentos em texto não criptografado, portanto, a senha do administrador será enviada para fazer login a cada inicialização.
if [ -n "${ADMINPASSWORD}" ]; then
  ARGS="${ARGS} -adminpassword ${ADMINPASSWORD}"
fi

# Senha do servidor
if [ -n "${PASSWORD}" ]; then
  ARGS="${ARGS} -password ${PASSWORD}"
fi

# Você pode escolher um nome de servidor diferente usando esta opção ao iniciar o servidor.
if [ -n "${SERVERNAME}" ]; then
  ARGS="${ARGS} -servername ${SERVERNAME}"
else
  # If not servername is set, use the default name in the next step
  SERVERNAME="servertest"
fi

# Se a predefinição estiver definida, o arquivo de configuração será gerado quando não existir ou SERVERPRESETREPLACE estiver definido como True.
if [ -n "${SERVERPRESET}" ]; then
  # Se o arquivo predefinido não existir, mostre um erro e saia
  if [ ! -f "${STEAMAPPDIR}/media/lua/shared/Sandbox/${SERVERPRESET}.lua" ]; then
    echo "*** ERROR: the preset ${SERVERPRESET} doesn't exists. Please fix the configuration before start the server ***"
    exit 1
  # Se os arquivos SandboxVars não existirem ou a substituição for verdadeira, copie o arquivo
  elif [ ! -f "${HOMEDIR}/Zomboid/Server/${SERVERNAME}_SandboxVars.lua" ] || [ "${SERVERPRESETREPLACE,,}" == "true" ]; then
    echo "*** INFO: New server will be created using the preset ${SERVERPRESET} ***"
    echo "*** Copying preset file from \"${STEAMAPPDIR}/media/lua/shared/Sandbox/${SERVERPRESET}.lua\" to \"${HOMEDIR}/Zomboid/Server/${SERVERNAME}_SandboxVars.lua\" ***"
    mkdir -p "${HOMEDIR}/Zomboid/Server/"
    cp -nf "${STEAMAPPDIR}/media/lua/shared/Sandbox/${SERVERPRESET}.lua" "${HOMEDIR}/Zomboid/Server/${SERVERNAME}_SandboxVars.lua"
    sed -i "1s/return.*/SandboxVars = \{/" "${HOMEDIR}/Zomboid/Server/${SERVERNAME}_SandboxVars.lua"
    # Remova o retorno do carro
    dos2unix "${HOMEDIR}/Zomboid/Server/${SERVERNAME}_SandboxVars.lua"
    # Eu vi que o arquivo é criado no modo de execução (755). Altere o modo de arquivo por motivos de segurança.
    chmod 644 "${HOMEDIR}/Zomboid/Server/${SERVERNAME}_SandboxVars.lua"
  fi
fi

# Opção para lidar com várias placas de rede. Exemplo: 127.0.0.1
if [ -n "${IP}" ]; then
  ARGS="${ARGS} ${IP} -ip ${IP}"
fi

# Definir o DefaultPort para o servidor. Example: 16261
if [ -n "${PORT}" ]; then
  ARGS="${ARGS} -port ${PORT}"
fi

# Opção para ativar/desativar o VAC nos servidores Steam. Na linha de comando do servidor, use -steamvac true/false. No arquivo INI do servidor, use STEAMVAC=true/false.
if [ -n "${STEAMVAC}" ]; then
  ARGS="${ARGS} -steamvac ${STEAMVAC,,}"
fi

# Os servidores Steam requerem duas portas adicionais para funcionar (acho que ambas são portas UDP, mas você também pode precisar de TCP).
# Estes são adicionais à configuração DefaultPort=. Estes podem ser especificados de duas maneiras:
#  - No arquivo INI do servidor como SteamPort1= e SteamPort2=.
#  - Usando variáveis ​​STEAMPORT1 e STEAMPORT2.
if [ -n "${STEAMPORT1}" ]; then
  ARGS="${ARGS} -steamport1 ${STEAMPORT1}"
fi
if [ -n "${STEAMPORT2}" ]; then
  ARGS="${ARGS} -steamport2 ${STEAMPORT1}"
fi

if [ -n "${PASSWORD}" ]; then
	sed -i "s/Password=.*/Password=${PASSWORD}/" "${HOMEDIR}/Zomboid/Server/${SERVERNAME}.ini"
fi

if [ -n "${MOD_IDS}" ]; then
 	echo "*** INFO: Found Mods including ${MOD_IDS} ***"
	sed -i "s/Mods=.*/Mods=${MOD_IDS}/" "${HOMEDIR}/Zomboid/Server/${SERVERNAME}.ini"
fi

if [ -n "${WORKSHOP_IDS}" ]; then
 	echo "*** INFO: Found Workshop IDs including ${WORKSHOP_IDS} ***"
	sed -i "s/WorkshopItems=.*/WorkshopItems=${WORKSHOP_IDS}/" "${HOMEDIR}/Zomboid/Server/${SERVERNAME}.ini"
fi


# Correção de um bug em start-server.sh que causa o não pré-carregamento de uma biblioteca:
# ERRO: ld.so: objeto 'libjsig.so' de LD_PRELOAD não pode ser pré-carregado (não pode abrir arquivo de objeto compartilhado): ignorado.
export LD_LIBRARY_PATH="${STEAMAPPDIR}/jre64/lib:${LD_LIBRARY_PATH}"

## Fixe as permissões nas pastas data e workshop
chown -R 1000:1000 /home/steam/pz-dedicated/steamapps/workshop /home/steam/Zomboid

su - steam -c "export LD_LIBRARY_PATH=\"${STEAMAPPDIR}/jre64/lib:${LD_LIBRARY_PATH}\" && cd ${STEAMAPPDIR} && pwd && ./start-server.sh ${ARGS}"
