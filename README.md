# 🌐 Servidor Web no Termux (Android)

Este projeto permite criar e configurar rapidamente um **servidor web** diretamente no  **Android**, usando o **Termux**. Ideal para testes locais, hospedagem leve e estudos.

---

## 📱 Requisitos

- Aplicativo [Termux](https://https://github.com/termux/termux-app/releases/latest) instalado
- Conexão com a internet (apenas para instalação de pacotes)

---

## ⚙️ Instalação

Abra o Termux e execute os comandos abaixo:

> Recomendo primeiro executar
> `termux-change-repo`
> e escolher um gupo mais proximo de sua localização

  `pkg update -y && pkg upgrade -y && pkg install git -y && git clone https://github.com/GabrielMDeveloper/web-server-termux && cd web-server-termux && chmod +x install.sh && ./install.sh`
