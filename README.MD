# [MONGA](https://www.github.com/mongagit) Project Zomboid Dedicated Server Container

Este Dockerfile baixa o servidor dedicado do [Monga Project Zombie](https://www.github.com/mongagit) usando o SteamCMD. Permitirá implantar com facilidade um servidor em Kubernetes, Docker...

A imagem pronta para uso está disponível aqui:

https://hub.docker.com/r/lorthe/project_zomboid_monga

## Environment Variables

Este dockerfile converte algumas variáveis ​​env em argumentos no comando do servidor. A imagem suporta as seguintes variáveis ​​de ambiente:

|Environment Variables|Description Variables|
|-|-|
|```SERVERNAME:```| Defina o nome do servidor.
|```ADMINPASSWORD:```| Senha do administrador. É obrigatório na primeira inicialização ou falhará.
|```PASSWORD:```| Senha do servidor. É opcional.
|```NOSTEAM:```| Inicia o servidor no modo NoSteam.
|```PORT:```| Porta do servidor. Por padrão 16261
|```WORKSHOP_IDS:```| Lista separada por ponto-e-vírgula de IDs de oficina para instalar no servidor
|```MOD_IDS:```| Lista separada por ponto-e-vírgula de Mod IDs para instalar no servidor
|```CACHEDIR:```| Defina a pasta padrão. Por padrão, odiretório inicial (/home/steam/Zomboid).
|```DEBUG:```| Ative o modo de depuração.
|```FORCEUPDATE:```| Force uma atualização a cada inicialização.
|```IP:```| Defina o IP da interface. Por padrão, todas as interfaces.
|```MEMORY:```| Quantidade de memória. Por padrão 8096m.
|```MODFOLDERS:```| Pastas usadas para os mods. As opções devem ser separadas por vírgula, por exemplo: workshop,steam,mods
|```SOFTRESET:```| Executa uma reinicialização suave no servidor.
|```STEAMVAC:```| Ativa ou desativa a proteção SteamVac no servidor
|```SERVERPRESET:```| O padrão é Apocalypse. Opções permitidas: Apocalypse, Beginner, Builder, FirstWeek, SixMonthsLater, Survival e Survivor.
|```SERVERPRESETREPLACE:```| Substitua a predefinição do servidor por aquela definida pela variável SERVERPRESET. Por padrão, false para evitar a substituição de configurações customizadas assim que o servidor for iniciado.
|```STEAMPORT1 & STEAMPORT2:```| Define as duas portas adicionais necessárias para funcionar. Eu acho que essas portas são UDP, mas também podem ser TCP.


Os mods serão instalados na inicialização do segundo servidor
## Reinicialização Suave

A reinicialização suave executará as seguintes tarefas:

* Remove itens do chão.
* Remove itens dos contêineres e os substitui por novos itens. Isso inclui contêineres feitos por jogadores.
* Remove cadáveres e jogadores zumbificados.
* Reseta os zumbis.
* Remove respingos de sangue.
* Redefine os alarmes do prédio.
* Redefine o relógio do jogo. Não tenho certeza se isso é redefinido para o dia 1, mas a postagem original do blog sugere que sim. Então isso traria água e eletricidade de volta. Supondo que as configurações do servidor os tenham *disponíveis no dia 1.
* Edifícios feitos por jogadores não serão excluídos.
* Os inventários dos jogadores não serão zerados.

Removendo os seguintes arquivos na pasta de dados do servidor (ToDo: tenho que pesquisar os arquivos equivalentes na versão moderna):
* all zombie_X_Y.bin files
* map_t.bin
* map_meta.bin
* reanimated.bin

Atualmente não está funcionando corretamente e fará com que o servidor trave quando estiver ativo. Além disso, os pontos acima não são executados, portanto, nada será alterado no servidor.

## Portas Necessárias

As portas necessárias estão documentadas no [wiki oficial](https://pzwiki.net/wiki/Dedicated_Server#Forwarding_Required_Ports)

Por enquanto as portas são as seguintes, mas pode mudar.

### Portas de Clientes Steam

Esta porta é utilizada pelos clientes Steam para se conectar com o servidor, portanto deve ser aberta no firewall e configurada no NAT.

* 8766 UDP
* 8767 UDP
* 16261 UDP (configurável)

### Portas de Clientes não Steam

Esta porta é utilizada pelos clientes No Steam para se conectar com o servidor, portanto deve ser aberta no firewall e configurada no NAT.

* 8766 UDP
* 8767 UDP
* 16261 UDP (configurável)
* 16262 -16272 TCP (a faixa depende da porta acima e dos slots dos clientes)

### Notas

* A porta 16261 pode ser alterada usando a variável de ambiente PORT. Isso afetará o intervalo de portas TCP, alterando-o para a próxima porta. Por exemplo, se PORT for definido como 12234, o intervalo TCP será 12234 -12244.
* O intervalo de portas TCP é usado pelos clientes, portanto, cada slot de cliente precisará de uma porta. Se o seu servidor planeja hospedar 50 clientes, você precisará abrir 50 portas no firewall/nat... (16262 -16312).
* O Wiki diz que as portas Non Steam devem ser para clientes não Steam, mas estou usando o cliente Steam e essas portas também são usadas.

## Como usar a imagem

Para configurar o servidor, você pode usar o programa docker-compose:

* Copie o .env.template para .env e edite-o com as configurações desejadas. A única variável obrigatória é ADMINPASSWORD e apenas na primeira vez que o servidor é executado (uma vez iniciado pelo menos uma vez, pode ser removido). As outras variáveis ​​são opcionais.
* Execute o`docker-compose up -d` comando para iniciar o servidor.

## Pasta de scripts

Nas pastas de scripts existem três scripts:

* entry.sh: O script usado na imagem para iniciar o servidor
* update_forum.sh: Verifique as postagens no fórum para atualizações e crie uma nova imagem se houver uma nova versão. Este script foi feito porque parece que a página oficial não atualiza a versão assim que sai.
* uodate_web.sh: Verifique a versão na página oficial e crie uma nova imagem se existir uma nova versão


