# Exercice 2
## Résumé

Objectif : le but de cet exercice est d'apprendre à manipuler Azure avec Ansible.

Les étapes de cet exercice : 
 - [Etape 1 : créer une webapp au travers du portail Azure](.#etape-1---cr%C3%A9er-une-webapp-via-le-portail-azure)
 - [Etape 2 : ajouter un storage account à votre déploiement via Azure Cli](.#etape-2---cr%C3%A9er-un-storage-account-en-utilisant-az-cli)
 - [Etape 2 : ajouter un storage account à votre déploiement via la cmdlet Powershell ARM](.#etape-3---cr%C3%A9er-un-storage-account-en-utilisant-la-cmdlet-powerhsell-arm)
 - [Etape 4 : ajouter une base de données Azure SQL DB via Azure ARM](.#etape-4---cr%C3%A9er-une-base-de-donn%C3%A9es-azure-sql-db-en-utilisant-un-template-arm)
    
## Pré-requis

- Une souscription Azure sur laquelle vous avez des droits à minima de contribution
  
## Etape 1 - Créer une Virtual Machine Azure avec ansible
Se connecter au portail Azure : https://portal.azure.com
Utiliser votre compte personnel disposant d'une souscription Azure

Dans cette étape, nous allons utiliser Ansible comme outil d'automatisation. Il peut être installé sur votre poste de travail ou être utilisé directement dans Azure via l'option Cloud Shell du portail Azure, nous utiliserons cette méthode dans l'exercice suivant

Sur le portail Azure, lancer le Cloud Shell  
![Cloud Shell](../Exercice1/images/step2_cloud_shell.PNG)  

Lors de sa première exécution, un popup va vous signaler que le Cloud Shell n'est pas configuré  
![Cloud Shell](./Exercice1/images/step2_cloud_shell_warning.PNG)  

Il faut donc le configurer. Pour cela, Azure va créer un Resource Group sur votre souscription avec un Storage Account qui servira à stocker le paramétrage du Cloud Shell. Si il n'y a pas de Cloud Shell existant pour votre souscription, merci de suivre les indications suivantes :
 - Cliquer sur advanced settings
 - Configurer les propriétés  
| Propriétés | Description | Valeur |
| --- | --- | --- |
| Cloud Shell region | Région d'hébergement | Choisir `France Central`
| Resource Group | Groupe de ressources pour votre Cloud Shell | Indiquer `cloudshell`
| Storage account | Utilisé pour sauvegarder les propriétés du CS | Indiquer `cloudshellsaXXXX` (XXXX = chaine de caractères aléatoire)*
| File share | File share qui sera utilisé pour sauvegarder votre espace CS dans le Storage Account | Choisir `cloudshellfs`
*un storage account doit avoir un nom unique dans une région donnée car cela réserve un alias DNS dans Azure qui doit être unique
![Cloud Shell properties](./Exercice1/images/step2_cloud_shell_properties.PNG)
 - Cliquer sur "create storage"

Une fois le Cloud Shell démarré, vous avez le choix entre une interface bash ou Powershell. Choisissez celle qui vous plait le plus. Cela n'a pas d'incidence sur l'usage d'ansible. Ici l'interface PowerShell
![Cloud Shell powershell](./images/step2_cloud_shell_powershell.PNG)  

> 👀 si vous utilisez Ansible sur votre poste, avant de suivre la suite de l'exercice, utilisez la commande suivante pour vous authentifier sur Azure et utiliser la bonne souscription : `az login` (nécessite az cli sur votre poste)

Configurer ensuite l'environnement de travail Azure à l'aide d'az cli :
 - Lister les souscriptions de votre abonnement : `az account show`
 - Choisir la souscriptions à manipuler : `az account set --subscription "XXXXX"` (où XXXXX = ID de votre souscription récupéré dans le résultat de la commande précédente)

Vous allez maintenant travailler sur ansible à la création d'un playbook permettant de créer une VM sur Azure.
Vous pouvez :
 - soit vous appuyez sur un playbook existant qui créer de base un certain nombre de ressources Azure utiles à l'hébergement de la VM
 - soit vous pouvez créer votre playbook from scrath. A noter qu'il vous faudra créer un Resource Group, un VNET, un subnet et un NSG en pré-requis de la création de la VM

Si vous créez votre playbook, merci de ne pas suivre les indications ci-dessous et de vous reporter à l'étape 2 une fois votre VM créée.

Si vous vous initiez à Ansible, vous pouvez vous appuyer sur le playbook [azure.yml](./azure.yml) existant dans le repo.
Examinons donc ce playbook ansible :
  - Télécharger le fichier azure.yml et éditez le avec l'éditeur de votre choix. Si vous le souhaitez, vous pouvez utiliser l'éditeur situé dans le Cloud Shell Azure en appuyant sur le bouton suivant ![Cloud Shell edit](./images/step4_cloud_shell_edit.PNG) une fois le CS démarré. vous pouvez même cloner le repo GitHub pour récupérer le fichier .yml via la commande `git clone https://github.com/mblanquer/azure-automation.git`  
  - Un playbook Ansible permet d'orchestrer des tâches qui seront exécutées sur un ensemble de machines. Se référer à la [documentation suivante](https://docs.ansible.com/ansible/latest/user_guide/playbooks_intro.html) pour en apprendre plus sur les playbooks Ansible
  - La structure du playbook est la suivante :  
    `- hosts: localhost`  
      `vars :`  
      `tasks:`  
        
    | Section | Description |
    | --- | --- |
    | hosts | Défini sur quel machine seront executées les tâches du playbooks. Ansible va alors regarder dans "l'inventory" configuré pour voir quelles sont les machines liées à la valeur renseignée dans ce paramètre "hosts". Dans notre cas, pour créer les ressources Azure, nous le faisons depuis notre machine / Cloud Shell donc nous l'avons défini à `localhost` 
    | vars | Défini les variables qui seront utilisées dans le playbook
    | tasks | Défini les tâches qui seront exécutées dans ce playbook

  - Zoom sur la section "vars" de ce playbook :  
    | Variable | Description | Valeur | 
    | --- | --- | --- |
    | var_rg | Nom du Resource Group à créer | `"dojoazure-{{user_id}}-ex02"` A noter qu'on utilise `{{user_id}}` pour faire référence à une autre variable. Ici `user_id` qui correspondra à l'id utilisateur (ex : us01), variable qui sera transmise à l'exécution du playbook
    | var_location | Région Azure utilisée | `francecentral` qui fait référence à la Région France Central
    | var_vnet_name | Nom du vnet à créer | `"vnet-{{user_id}}-ex02"`
    | var_subnet_vm_name | Nom du subnet qui sera créé pour la VM | `"vms"` Ce subnet sera créé dans le vnet
    | var_nsg_vm_name | Nom du Network Security Group (NSG) créé pour protéger le subnet | `"nsg-{{user_id}}-ex02-vms-nsg"` Ce NSG sera associé au subnet vms et protégera ce dernier au travers de règles de filtrage réseau
    | var_tags | Tags à appliquer sur les ressources | `project: dojoazure user: us01 exercice: ex02`  
      
    - Zoom sur la section "tasks" de ce playbook : 
    | Task | Description | 
    | --- | --- | 
    | Create resource group | Tâche de création du Resource Group (RG) dans lequel seront créés les ressources Azure. S'appuie sur le module ansible "azure_rm_resourcegroup" auquel sont passés différents paramètres : name (nom du RG) et location (région pour ce RG)
    | Create Vnet | Tâche de création du VNET sur lequel sera hébergé la VM. S'appuie sur le module ansible "azure_rm_virtualnetwork" auquel sont passés différents paramètres : name (nom du vnet), resource_group (RG du vnet), address_prefixes_cidr (CIDRs du vnet), tags (tags pour ce vnet)
    | Create NSG for VMs subnet | Tâche de création d'un Network Security Goup (NSG) qui permettra de définir des règles firewall à appliquer. Cela peut être fait sur un subnet ou directement sur une NIC (Network Interface) d'une VM. S'appuie sur le module ansible "azure_rm_securitygroup" auqeul sont passés différents paramètres : name (nom du NSG), resource_group (RG du NSG), purge_rules (permet de préciser à Ansible de purger les règles existantes avant application des nouvelles), rules (règles firewall à appliquer avec différents paramètres décrits [ici](https://docs.ansible.com/ansible/latest/modules/azure_rm_securitygroup_module.html))
    | Create VMs subnet | Tâche de création du subnet qui hébergera la VM. s'appuie sur le module ansible "azure_rm_subnet" auquel sont passés différents paramètres : name (nom du subnet), resource_group (RG du subnet), virtual_network_name (VNET du subnet), address_prefix_cidr (CIDR du subnet), security_group (NSG du subnet)  
      
    A noter l'usage de :
     - register : permet d'enregistrer dans une variable le résultat de la tâche
     - debug : tâche qui permet d'écrire dans la console. Dans ce playbook, utilisé pour écrire le résultat des tâches via la variable alimentée par le "register" des tâches de création de ressources

Une fois la structure et le contenu du playbook en tête, voici la commande à exécuter pour l'exécuter :  
`ansible-playbook azure.yml --extra-vars "user_id=usXX"` (où usXX = id utilisateur, valeur transmise à la variable `user_id` utilisée pour définir les noms des ressouces Azure)  

Cela va donc créer les ressources dans Azure, de la sorte :  
![Resources prerequistes created](./images/step1_results.PNG)  
![VNET created](./images/step1_results2.PNG)  
![Subnet created](./images/step1_results3.PNG)  
![NSG created](./images/step1_results4.PNG)  

> 📘 Ce playbook vous a permis de créer les pré-requis à la création de votre Virtual Machine

 Ajoutons maintenant la virtual machine à ce playbook :
  - Dans la section "vars", ajouter la variable suivante qui correspondra au nom de la Virtual Machine :  
        `var_vm_name: "vm-{{user_id}}-ex02"`  
  - Dans la section "tasks", ajouter ensuite le bloc suivant pour la création de la Virtual Machine :  
        `- name : Create VM Windows`  
          `azure_rm_virtualmachine:`  
            `name: "{{var_vm_name}}"`  
            `resource_group: "{{var_rg}}"`  
            `admin_username: "admincheops"`  
            `admin_password: "{{admin_password}}"`  
            `managed_disk_type: Standard_LRS`  
            `virtual_network_name: "{{var_vnet_name}}"`  
            `subnet_name: "{{var_subnet_vm_name}}"`  
            `os_type: "Windows"`  
            `image:`  
                `offer: "WindowsServer"`  
                `publisher: "MicrosoftWindowsServer"`  
                `sku: "2019-Datacenter"`  
                `version: "latest"`  
            `vm_size: "Standard_DS1_v2"`  
          `register : vm_windows`  
  - Toujours dans la sections "tasks", ajouter le bloc suivant pour visualiser le résultat de la création de la VM (variable vm_windows du paramètre register de la tâche de création de VM) :  
        `- debug:` 
            `var: vm_windows` 
  
  Rexécuter votre template :
 - Aller dans le cloud shell 
 - Lancer la commande suivante :  
`ansible-playbook azure.yml --extra-vars "user_id=usXX admin_password=YYYY"` où  
    - usXX = id utilisateur, valeur transmise à la variable `user_id` utilisée pour définir les noms des ressouces Azure
    - admin_password = le password du compte admin de la machine "admincheops". Choisir le mot de passe de votre choix
 - Vous devriez voir votre Virtual Machine créée dans le Resource Group :
 ![step 1 results](./images/step1_results_VM.PNG) 

Le playbook correspondant aux ajouts effectués ci-dessous est [azure_vm.yml](./azure_vm.yml)

> 👏 Bravo, votre Virtual Machine est créée via un playbook Ansible !  
 
## Etape 3 - Créer un Storage Account en utilisant la cmdlet Powerhsell ARM
A l'instar de l'étape précédente, nous allons utiliser le Cloud Shell pour utiliser la cmdlet Powershell ARM. C'est un module powershell qui permet de manipuler Azure via Azure Resource Manager

Sur le portail Azure, aller sur le Cloud Shell  

Une fois le Cloud Shell démarré, vous avez le choix entre une interface bash ou Powershell. Choisissez l'interface Powershell
![Cloud Shell powershell](./images/step2_cloud_shell_powershell.PNG)  

> 👀 si vous utilisez le module Powershell sur votre poste, bien vous authentifier sur Azure via la commande `Login-AzAccount` avant de suivre la suite de l'exercice

Configurer ensuite l'environnement de travail Azure à manipuler avec az cli :
 - Lister les souscriptions de votre abonnement : `Get-AzSubscription`
 - Choisir la souscriptions à manipuler : `Select-AzSubscription -SubscriptionId "XXXXX"` (où XXXXX = ID de votre souscription récupéré dans le résultat de la commande précédente)
  - A tout moment, pour une aide sur une commande `Get-Help XXX`(où XXX = commande sur laquelle obtenir de l'aide)

Ensuite, voici la commande à exécuter pour créer le Storage Account de cet exercice :  
`New-AzStorageAccount -Name dojoazureus01ex01ps -ResourceGroupName dojoazure-us01-ex01 -Location francecentral -EnableHttpsTrafficOnly $true -Kind StorageV2 -sku Standard_LRS  -Tags @{project="dojoazure";exercice="ex01";user="us01"}`
  
Quelques explications :
| Propriétés | Description | Valeur |
| --- | --- | --- |
| -Name | Nom du Storage Account à créer | Ici `dojoazureus01ex01ps` (attention, nom unique pour la région)
| -ResourceGroupName | Nom du RG dans lequel créer le Storage Account | Ici `dojoazure-us01-ex01` (idem à l'étape 1 de cet exercice)
| -Location | Région du Storage Account | Ici `francecentral`
| -EnableHttpsTrafficOnly | Paramètre qui précise que le Storage Account ne sera utilisable qu'en https | ici boolean `$true`
| -Kind | Paramètre pour préciser le type de Storage Account | Ici `StorageV2` qui indique la V2
| -Sku | Paramètre pour préciser le SKU du Storage Account | Ici `Standard_LRS` qui indique que le storage sera de type Standard et en LRS ([cf. SKU Storage Account](https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types))
| -Tags | Tags associés au Storage Account | Ici `@{project="dojoazure";exercice="ex01";user="us01"}` (idem aux tags utilisés pour la WebApp de l'étape 1)
  
![Storage Account created PS](./images/step3_results.PNG)  

> 👏 Bravo, votre Storage Account est créé via la cmdlet Powershel ARM !

## Etape 4 - Créer une base de données Azure SQL DB en utilisant un template ARM
Dans cette nouvelle étape, nous allons cette fois utiliser une méthode d'Infra As A Code qui permet de créer des ressources Azure en utilisant un langage descriptif s'appuyant sur les Templates ARM. Basé sur Azure Resource Manager, les templates ARM permettent de décrire l'infrastructure Azure souhaitée au format json puis lors de l'exécution, les API ARM Azure sont sollicités pour interprêter le template

Le fichier [azdeploy.json](./azdeploy.json) correspond à un template ARM qui permet de déployer les Etapes 1 à 3 de cet exercice.

Vous pouvez déployer ce template en allant sur le Cloud Shell (interface powerhshell) et en exécutant la commande suivante :  
`New-AzResourceGroupDeployment -Name deployARMTemplate -ResourceGroupName dojoazure-us01-ex01 -TemplateUri https://raw.githubusercontent.com/mblanquer/azure-automation/prepa_dojo/Exercice1/azuredeploy.json -TemplateParameterObject @{"user_id"="usXX"}`  
(où usXX = votre id user, par exemple "us01")
  
Quelques explications :
| Propriétés | Description |
| --- | --- | 
| New-AzResourceGroupDeployment | Commande Powershell pour le déploiement sur RG de templates ARM
| -Name | Nom du déploiement
| -ResourceGroupName | Nom du RG dans lequel créer le Storage Account
| -Location | Région du Storage Account
| -TemplateUri | Url du template ARM à exécuter
| -TemplateParameterObject | Passage des paramètres au template ARM sous forme d'objet

Les logs du déploiement de template ARM sont visibles dans l'écran "Deployments" du Resource Group concerné par le déploiement :  
![RG deployment ARM Template logs](./images/step4_logs_ARM_deployment.PNG)  

Avant de poursuivre l'exercice, il convient de comprendre la structure d'un template ARM :  
{  
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",  
    "contentVersion": "1.0.0.0",  
    "parameters": {},  
    "variables": {},  
    "resources": [],  
    "outputs": {}  
}  
  
| Propriétés | Description |
| --- | --- |
| $schema | Lors de l'exécution du template, ce schéma sera utilisé pour vérifier que la syntaxe et les propriétés utilisées dans le json sont correctes
| contentVersion | Permet de versionner le template 
| parameters | Section qui permet de définir les paramètres attendus par le template. Dans ce template c'est le `user_id` qui permet d'identifier l'utilisateur. Cette valeur est ensuite utilisée pour définir un ensemble de noms utilisés sous forme de variables
| variables | Section qui permet de définir des variables utilisées dans le template. Dans ce template, les noms des différentes ressources sont définis sous forme de variables qui utilise le paramètre `user_id` pour l'unicité des noms
| resouces | Section qui permet de définir les ressources Azure à déployer. Il convient de renseigner le "provider" qui correspond au type de ressource mais aussi "l'api version" qui définit la version d'API ARM à utiliser
| outputs | Section qui permet de définir quels seront les outputs de ce template lors de son exécution

_Remarque_ : la doc des API ARM et des propriétés attendues par ressource est disponible [sur ce lien](https://docs.microsoft.com/en-us/azure/templates/microsoft.aad/allversions)
  
Quelques fonctions utilisées dans le template :
 - `[ResourceGroup().location]` : utilisé pour définir que la location d'une ressource hérite de la location du Resource Group dans lequel elle est déployée
 - `[concat()]` : permet de concatener des paramètres/variables/chaines de caractères
 - `[parameters('xxx')]`: permet de faire référence au paramètre xxx reçu en input du template
 - `[variables('xxx')]`: permet de faire référence à la variable xxx définie dans le template
 - `dependsOn`: permet de spécifier que le déploiement de la ressource concernée est dépendante du déploiement d'une autre resource Azure définie dans le template. Automatiquement, ARM va attendre que cette ressource soit déployée pour déployer la ressource définie. Dans le cas contraire, il parallélise le déploiement des deux ressources

 > 📘 Vous savez comment est structuré un template ARM et comment l'exécuter pour créer vos ressources dans Azure !

 Ajoutons maintenant la base de données à ce template :
  - Télécharger le fichier azdeploy.json et éditez le avec l'éditeur de votre choix. Si vous le souhaitez, vous pouvez utiliser l'éditeur situé dans le Cloud Shell Azure en appuyant sur le bouton suivant ![Cloud Shell edit](./images/step4_cloud_shell_edit.PNG) une fois le CS démarré. vous pouvez même cloner le repo GitHub pour récupérer le fichier .json via la commande `git clone https://github.com/mblanquer/azure-automation.git`  
  ![Cloud Shell edit view](./images/step4_cloud_shell_edit_view.PNG)  
  - Dans la section "parameters", ajouter le paramètre suivant qui sera utilisé pour créer un password unique pour le compte admin SQL :  
        `"date": {`  
            `"type": "String",`  
            `"defaultValue": "[utcNow()]"`  
        `}`  
  - Dans la section "variables", ajouter les deux variables suivantes qui correspondront aux noms de l'Azure SQL Server et à l'Azure SQL Database :  
        `"dbserver_name" : "[concat(parameters('user_id'), '-db')]",`  
        `"db_name" : "[concat(parameters('user_id'), '-db')]"`  
  - Toujours dans la section "variables", ajouter la variable suivante qui créé un mot de passe unique pour le compte admin d'Azure SQL Server :  
        `"administratorLoginPassword" : "[concat('db', uniqueString(concat(parameters('user_id'), variables('dbserver_name'), parameters('date'))),'!')]"`
  - Dans la sections "resources", ajouter ensuite le bloc suivant pour la création de l'Azure SQL Server :  
        `{`  
            `"type": "microsoft.sql/servers",`  
            `"apiVersion": "2019-06-01-preview",`  
            `"name": "[variables('dbserver_name')]",`  
            `"location": "[resourceGroup().location]",`  
            `"tags": "[variables('tags')]",`  
            `"properties": {`  
                `"administratorLogin": "adminDB",`  
                `"administratorLoginPassword": "[variables('administratorLoginPassword')]"`  
            `}`  
        `}`  
  - Dans la sections "resources", ajouter ensuite le bloc suivant pour la création de l'Azure SQL DB :  
        `{`  
            `"type": "microsoft.sql/servers/databases",`  
            `"apiVersion": "2019-06-01-preview",`  
            `"name": "[concat(variables('dbserver_name'), '/', variables('db_name'))]",`  
            `"location": "[resourceGroup().location]",`  
            `"dependsOn": ["[variables('dbserver_name')]"],`  
            `"tags": "[variables('tags')]",`  
            `"sku": {`  
                `"name": "GP_S_Gen5",`  
                `"tier": "GeneralPurpose",`  
                `"family": "Gen5",`  
                `"capacity": 1`  
            `},`  
            `"kind": "v12.0,user,vcore,serverless",`  
            `"properties": {`  
                `"maxSizeBytes": 1073741824,`  
                `"autoPauseDelay": 60,`  
                `"minCapacity": 0.5`  
            `}`  
        `}`  
  
Rexécuter votre template :
 - Aller dans le cloud shell en interface PowerShell
 - Uploader votre template via le bouton ![Cloud Shell upload](./images/step4_cloud_shell_upload.PNG) sauf si vous l'avez édité directement dans le Cloud Shell  
 - Lancer la commande suivante :  
 `New-AzResourceGroupDeployment -Name deployARMTemplate -ResourceGroupName dojoazure-us01-ex01 -TemplateFile ./azuredeploy.json -TemplateParameterObject @{"user_id"="usXX"}`  
 (où usXX = votre id user, par exemple "us01")
 - Vous devriez voir votre Azure SQL DB et Azure SQL Server créé dans le Resource Group :
 ![step 4 results](./images/step4_results.PNG) 

Le template ARM correspondant aux ajouts effectués ci-dessous est [db_azdeploy.json](./db_azuredeploy.json)

> 👏 Bravo, votre database Azure SQL est créé via un template ARM !


----------------------------------------------------------------------------------------------------------------
Au travers de cet exercice, vous avez appris à :
 - vous familiarisez avec Azure
 - à manipuler des ressources Azure via le Portail Azure
 - à manipuler des ressources Azure via l'interface de commande az cli
 - à manipuler des ressources Azure via la cmdlet Powershell ARM
 - à manipuler des ressources Azure via un template ARM