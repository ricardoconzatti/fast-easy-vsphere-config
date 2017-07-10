# Fast and Easy vSphere Configuration

Este script utiliza o vSphere PowerCLI para criar um ambiente completo no vSphere com iSCSI, tudo de forma interativa e seguindo as recomendações de configurações da VMware.

 - **Ações que o Script executa**
	 - **Configuration**
		 - Define o hostname do vCenter Server, quantidade de hosts ESXi e hostname
	 - **Test Servers**
		 - Realiza o Flush / Register DNS (opcional) e testa a conexão dos servidores (ping) cadastrados no item Configuration
	 - **vCenter Server**
		 - Connecta no vCenter Server
	 - **Data Center**
		 - Cria um novo data center e lista os hosts ESXi existentes, sendo possível exportar o relatório em CSV ou HTML
	 - **Cluster**
		 - Cria um novo cluster, adiciona os hosts ESXi, configura o HA e DRS e lista os hosts ESXi existentes
	 - **Network**
		 - **VDS**
			 - Cria um novo VDS, adiciona os hosts ESXi, adiciona uplinks, migra o port group de gerencia do VSS para VDS e lista os VDS existentes
		 - **Port Group**
			 - Cria novos port groups (generico), cria port group para vMotion, cria port group para iSCSI e lista os port groups existentes
		 - **VMkernel**
			 - Cria novo VMkernel (generico), cria VMkernel para vMotion, cria VMkernel para iSCSI e lista os VMkernel existentes
		 - **iSCSI**
			 - Configura o iSCSI, adiciona o iSCSI software adapter, adiciona o VMkernel (vmk2 e vmk3) no port binding, adiciona o send target portal e faz um rescan no host ESXi
	 - **ESXi**
		 - Configura o NTP, SSH e Maintenance Mode
	 - **VM**
		 - Configura a criação de máquinas virtuais utilizando o linked clone
	 - **TAG**
		 - Cria categorias para as tags, cria tags e associa as tags com máquinas virtuais
 - **Compatibilidade**
	 - vSphere (ESXi e vCenter)
		 - Testado nas versões 5.1, 5.5, 6.0 e 6.5
	 - PowerCLI
		 - Recomendo a versão 6 ou superior
 - **Pré-requisitos**
	 - vCenter Server (Windows ou Appliance) versão 5 ou superior
	 - Garantir que o vCenter esteja acessivel pela rede
	 - VMware vSphere PowerCLI versão 6 ou superior
	 - 2 ou mais hosts ESXi 6.0 ou superior
		 - Garantir que o ESXi esteja acessível pela rede. Configurar o IP, DNS e hostname
	 - Criar entradas DNS para todos os hosts ESXi e vCenter
		 - Resolução de nomes (curto e FQDN)

[Mais informações](http://solutions4crowds.com.br/script-fast-and-easy-vsphere-configuration)
