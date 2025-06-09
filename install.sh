#!/bin/bash

export PATH=$PREFIX/bin:$PATH
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
atalhos_dir="$HOME/atalhos-servidor"

install_apache(){
  echo -e "\n Instalando Apache \n"
  pkg install apache2 -y
  echo -e "\n Apache instalado!\n"
}

install_php(){
  echo -e "\nInstalando php + php-apache\n"
  pkg install php php-apache -y
  echo
  echo -e "php instalado!\n"
}

install_mariadb(){
  echo -e "\nInstalando MariaDB\n"
  pkg install mariadb -y
  echo
  echo -e "mariadb instalado!\n"
}

install_full(){
  echo -e "\nInstalando apache, php, mariadb, libqrencode...\n"
  pkg install -y apache2 php php-apache mariadb libqrencode
  echo -e "\n Pacotes instalados!\n"
}


apache_bck() {
  arquivo_httpd="$PREFIX/etc/apache2/httpd.conf"

  arquivo_httpd_bck="$PREFIX/etc/apache2/httpd.conf.bck"

  # verifica para que o backup seja realizado
  #apenas uma vez
  if [ ! -f "$arquivo_httpd_bck" ]; then
  echo -e "\nCriando backup de: \n $arquivo_httpd"
  cp "$arquivo_httpd" "$arquivo_httpd_bck"
  sleep 2
  echo -e "\nBackup criado com sucesso:"
  echo -e "$arquivo_httpd_bck \n"
  else
    echo -e "\nBackup de httpd.conf em: $arquivo_httpd_bck \n"
  fi
}

apache_conf() {
  echo -e "\n Configurando Apache... \n"
  #Descomenta a linha prefork
  sed -i '/#LoadModule mpm_prefork_module libexec\/apache2\/mod_mpm_prefork.so/s/^#//' $PREFIX/etc/apache2/httpd.conf

  #Comenta a linha worker
  sed -i '/^LoadModule mpm_worker_module libexec\/apache2\/mod_mpm_worker.so/s/^/#/' $PREFIX/etc/apache2/httpd.conf
  
  #adiciona index.php como prioridade
  sed -i '/DirectoryIndex index.html/s/index.html/index.php index.html/' $PREFIX/etc/apache2/httpd.conf

  #Arquivo de configuração do usuario
  file_dir="$PREFIX/etc/apache2/conf.d/user.conf"
  # linhas que sera adicionada ao arquivo
  file_text="AddHandler php-script .php \nLoadModule php_module libexec/apache2/libphp.so \n\n<IfModule dir_module> \n  DirectoryIndex index.php index.html \n</IfModule>\n\nServerName localhost:8080"

  if [ ! -f "$file_dir" ]; then
  echo -e "\nCriando arquivo de configuração do usuario\n"

  touch "$file_dir"
  echo -e "$file_text" > "$file_dir"
  sleep 1
  echo -e "Apache configurado! \n \n Arquivo de configuração: \n $file_dir"
  else
    echo -e "Apache já configurado! \n \n Arquivo de configuração:\n $file_dir"
  fi
  
  echo -e "\nCriar arquivo .php para testar apache e php? (Y/n)"
  read resposta
  resposta=${resposta,,}

  if [ $resposta = 'y' ]; then
      echo -e "\n Criando arquivo 'index.php' \n"
      test_php_dir="$PREFIX/share/apache2/default-site/htdocs/index.php"
      
      touch "$test_php_dir"
      echo -e "<?php\nphpinfo()\n?>" > "$test_php_dir"
      echo -e "Arquivo criado!\n"
      apachectl stop
      apachectl start
      echo -e "\nA url será aberta em seu navegador: http://localhost:8080\n"
      sleep 2
      termux-open "http://localhost:8080"
  else
      # Senão
      echo -e '\nPulando teste\n'
  fi
} #apache_conf

server_copy(){
  local server_dir="$REPO_DIR/.server"
  local final_server_dir="$HOME"

  #Verifica se ainda não foi copiado
  if [ ! -d "$final_server_dir/.server" ]; then

    #verifica se a pasta existe no repo clonado
    if [ -d "$server_dir" ]; then
      cp -r "$server_dir" "$final_server_dir"
      chmod -R +x "$final_server_dir/.server/"
      echo "Pasta foi copiada: $final_server_dir/.server"
    else
      echo "A pasta não foi encontrada, atalhos não instalados"
    fi

  else
    echo "A Pasta já foi copiada: $final_server_dir/.server"
  fi
}

config_server(){
  apache_bck
  apache_conf
  shell_detect
  config_atalhos
  server_copy
}

config_atalhos(){
    atalhos_apache="$atalhos_dir/apache-conf"

    a_apache_conf="$PREFIX/etc/apache2/httpd.conf"
    a_apache_user_conf="$PREFIX/etc/apache2/conf.d/user.conf"
    a_htdocs_dir="$PREFIX/share/apache2/default-site/htdocs"
    a_php_conf="$PREFIX/lib/php.ini"

    mkdir -p "$atalhos_dir"
    mkdir -p "$atalhos_apache"
    touch "$a_php_conf"
    
    #ATALHO APACHE
    ln -sf "$a_apache_conf" "$atalhos_apache/httpd.conf"
    ln -sf "$a_apache_user_conf" "$atalhos_apache/user.conf"
    ln -sf "$a_htdocs_dir" "$atalhos_dir/htdocs"
    ln -sf "$a_php_conf" "$atalhos_dir/php.ini"
}


shell_config() {
local shell_rc_file="$1" # Recebe o caminho do arquivo .rc

SHELL_CONTENT_TXT="$(cat << 'EOF'
#Configurações geradas por:
#(https://github.com/GabrielMDeveloper/web-server-termux)

# Exporta o ~/.server para o PATH
export PATH="$PATH:$HOME/.server:/data/data/com.termux/files/usr/bin/applets"

#Inicia o daemon do mariadb ao iniciar o termux
mariadbctl start

#Cria o alias qrcode para facilitar o uso manual
alias qrcode="qrencode -t utf8"
EOF
)"

#INCIO COM BOOT SERVIDOR WEB
echo "Deseja iniciar o servidor web toda vez que iniciar o temux? (Y/n)"
read resposta

if [[ "$resposta" =~ ^[Yy]$ || -z "$resposta" ]]; then

SHELL_CONTENT_TXT+="
$(cat << 'EOF'
# Função para iniciar o web-server ao abrir o terminal
boot_start_server(){
  echo -e "\nIniciar servidor web? (Y/n)"
  read respost
  # Verifica se o usuario digitou sim ou apertou <enter>
  if [[ "$respost" =~ ^[Yy]$ || -z "$respost" ]]; then
      web-server start
  else
      echo -e "\nServidor não iniciado\n"
  fi
}
boot_start_server
##### web-server-termux #####
EOF
)"  
  fi #INCIO COM BOOT SERVIDOR WEB

  # Verifica se o .*rc existe
  if [ -f "$shell_rc_file" ]; then
      #Verifica se o conteudo ainda não foi adicionado
      if ! grep -qF "$SHELL_CONTENT_TXT" "$shell_rc_file"; then
          # adiciona o conteudo ao arquivo já existente
          echo -e "\nAdicionando configuracoes ao $shell_rc_file...\n"
          echo "$SHELL_CONTENT_TXT" >> "$shell_rc_file"
          echo -e "\nConteúdo adicionado com sucesso a $shell_rc_file.\n"         

      else
          echo -e "\nConteúdo ja existe em $shell_rc_file. Nenhuma alteracao necessaria.\n"
      fi

  else
    # Cria o arquivo e escreve nele
    echo "Criando $shell_rc_file..."
    touch "$shell_rc_file"
    echo -e "\nEscrevendo configuracoes no $shell_rc_file...\n"
    echo "$SHELL_CONTENT_TXT" >> "$shell_rc_file"    
    echo -e "\n$shell_rc_file configurado\n"  
  fi

} # shell_config()

#Detecta qual é o shell do usuario:
shell_detect() {
    echo -e "\nDetectando o shell atual...\n"

    if [[ "$SHELL" == *"/bash"* ]]; then
        echo "Bash detectado."
        shell_config "$HOME/.bashrc"

    elif [[ "$SHELL" == *"/zsh"* ]]; then
        echo "Zsh detectado."
        shell_config "$HOME/.zshrc"

    elif [[ "$SHELL" == *"/fish"* ]]; then
        echo "Fish detectado."
        shell_config "$HOME/.config/fish/config.fish"

    else
        echo "Shell nao reconhecido ou nao suportado para configuracao automatica: $SHELL"
        echo "Por favor, adicione as configuracoes manualmente ao seu arquivo de inicializacao do shell."
        echo -e "Conteudo a ser adicionado:\n\n$SHELL_CONFIG_CONTENT"
    fi
} #shell_detect()

source_rc(){
  if [[ "$SHELL" == *"/bash"* ]]; then
      source "$HOME/.bashrc"

  elif [[ "$SHELL" == *"/zsh"* ]]; then
      source "$HOME/.zshrc"

  elif [[ "$SHELL" == *"/fish"* ]]; then
      source "$HOME/.config/fish/config.fish"

  else
      echo "Shell nao reconhecido ou nao suportado para: source $SHELL"
  fi
}

alertas_finais(){
  local help_txt="$atalhos_dir/help.txt"
  local texto="\n\n
  Você pode controlar o servidor com o comando:
  [web-server {start|stop|restart}] 

  ou controlar o mariadb com:
  [mariadbctl {start|stop|restart}] 

  *Extra! Você pode mostrar um qrcode usando:
  [qrcode {texto ou link}]
  ex: qrcode localhost:8080
  
  Para iniciar o Mariadb pela primeira vez você deve executar: \n
  mariadb-install-db \n
  mariadb-upgrade --force \n
  mariadb-secure-installation \n

  Atenção: em seu arquivo de configuração mysql use o endereço 127.0.0.1 para acessar o servidor local.
  Evite usar 'localhost' para evitar erros de conexão com o banco de dados, pois necessita de maiores configurações.

  Estes avisos estão disponiveis em:
  \$HOME/atalhos-servidor/help.txt"
  
  touch "$help_txt"
  echo -e "#Gerado por:\n#(https://github.com/GabrielMDeveloper/web-server-termux)\n" >> "$help_txt"
  echo -e "$texto" >> "$help_txt"
}

full_install_server(){
    install_full
    config_server
    source_rc
}

instalador(){
    # Loop infinito.
    while :; do
        # limpa a tela
        clear

        # Menu
        echo ===== Instalar e configurar web server php =====
        echo
        echo '1) Instalar Apache'
        echo '2) Instalar PHP'
        echo '3) Instalar Mariadb'
        echo '4) Instalar Todos'
        echo '5) Configurar Servidor (necessario ter todos os pacotes instalados)'
        echo '6) INSTALAR E CONFIGURAR TODOS (SERVIDOR TOTALMENTE FUNCIONAL)'
        echo '7) Sair'

        # Lê somente o primeiro caractere digitado.
        read -n1 -p 'Opção: ' opc
        echo

        # Verifica o valor armazenado em 'opc' e
        # executa o bloco referente.
        case $opc in
            1)  install_apache;;
            2)  install_php;;
            3)  install_mariadb;;
            4)  install_full;;
            5)  config_server;;
            6)  full_install_server;;
            7)  break;; # Interrompe o loop e finaliza a exibição do menu.
            *)  echo 'OPÇÃO INVÁLIDA !!'
        esac

        read -p 'Pressione ENTER para voltar...'
    done

    echo 'Saindo...'
    alertas_finais
}

instalador