# Exercice 1
## Résumé
Objectif : le but de cet exercice est de se familiariser avec Azure et le déploiement de ressources dans Azure avec le portail Azure dans un premier temps puis au travers du déploiement via Az Cli et Azure Resource Manager (ARM).

Tâches : 
 - [Etape 1 : créer une webapp au travers du portail Azure](.#etape-1---cr%C3%A9er-une-webapp-via-le-portail-azure)
 - [Etape 2 : ajouter un storage account à votre déploiement via Azure Cli](.#etape-2---cr%C3%A9er-un-storage-account-en-utilisant-az-cli)
 - [Etape 3 : ajouter une base de données Azure SQL DB via Azure ARM](.#etape-3---cr%C3%A9er-une-base-de-donn%C3%A9es-azure-sql-db-en-utilisant-un-template-arm)

## Etape 1 - Créer une WebApp via le portail Azure
Se connecter au portail Azure : https://portal.azure.com
Utiliser votre compte personnel disposant d'une souscription Azure

Dans le "burger menu", choisir "Create a resource"  
![Create a resource2](./images/step1_create_resource.PNG)

Puis chercher le terme "web app"  
![Create a Web App](./images/step1_search_create_webapp.PNG)

Appuyez vous sur le tableau ci-dessous pour le choix des propriétés de votre WebApp  
![Web App properties](./images/step1_webapp_properties.PNG)

| Propriétés | Description | Valeur |
| --- | --- | --- |
| Subscription | Souscription sur laquelle sera créée la WebApp | Votre souscription
| Resource Group | Groupe de ressources dans lequel sera créé la WebApp | Cliquez sur "Create new" et choisir `dojoazure-us01-ex01` (us01 = votre id de user)
| Name | Votre nom de webapp | Choisir `webapp-us01-ex01` (us01 = votre id de user)
| Publish | Méthode de déploiement : Code = runtime pré-installé, Docker Container = image docker à fournir | Choisir `Code`
| Runtime stack | Runtime pré-installé | Choisir `ASP.NET V4.7`
| Operating system | OS sous-adjacent utilisé | Champ pré-selectionné par Azure
| Region | Région Azure d'hébergement | Choisir `France Central`

Pour la sous-section App Service Plan
| Propriétés | Description | Valeur |
| --- | --- | --- |
| Windows plan | App Service plan qui sera utilisé par votre WebApp | Cliquer sur "Create New"
| Name | Nom de votre ASP | Choisir `webapp-us01-ex01-asp` (us01 = votre id de user)
| Sku and size | Sizing de votre ASP (nombre et taille de machines/instances) | Choisir `Dev/Test - F1` (ASP Gratuit)

Une fois complété :  
![Web App properties filled](./images/step1_webapp_properties_filled.PNG)

> 📘 Vous avez configurée votre WebApp avec son App Service Plan associé

Cliquez sur next pour passer à la partie "Monitoring" et configurer la section ainsi  
![Web App appInsights](./images/step1_webapp_monitoring.PNG)

> 📘 Votre WebApp sera associée directement l'Application Insights renseigné pour son monitoring

Cliquez sur next pour passer à la partie "Tags" et configurer la section ainsi  
![Web App tags](./images/step1_webapp_tags.PNG)

> 📘 Les tags utilisés peuvent être utiles pour différentes activités : management, FinOps, monitoring...

Cliquez sur "Review + create" puis "Create" une fois la validation Azure passée

Une fois le déploiement effectuée, allez sur votre Resource Group `dojoazure-usXX-ex01` et observez les resources créées : 
 - Votre WebApp `webapp-usXX-ex01` qui hébergera votre application
 - Votre WebApp `webapp-usXX-ex01-asp` qui définit la puissance allouée à votre webapp (nombre et tailles des machines/instances sous-adjacentes)
 - Votre Application Insights `webapp-usXX-ex01-ai` qui capturera automatiquement les données de monitoring de votre application
  
![Web App RG](./images/step1_webapp_RG_results.PNG)

L'application web est consultable en allant sur le lien transmis dans les propriétées de votre WebApp :  
![Web App url](./images/step1_webapp_url.PNG)
  
![Web App browse](./images/step1_webapp_browse.PNG)
  
> 👏 Bravo, votre WebApp est déployée ! 

## Etape 2 - Créer un Storage Account en utilisant az cli
Dans cette étape, nous allons utiliser l'interface de ligne de commande Azure appelée az cli.
Elle peut être installée sur votre poste de travail en suivant [ce lien](#https://docs.microsoft.com/fr-fr/cli/azure/install-azure-cli?view=azure-cli-latest) ou via l'option Cloud Shell du portail Azure, nous utiliserons cette méthode dans l'exercice suivant

Sur le portail Azure, lancer le Cloud Shell
![Cloud Shell](./images/step2_cloud_shell.PNG)  

Lors de sa première exécution, un popup va vous signaler que le Cloud Shell n'est pas configuré
![Cloud Shell](./images/step2_cloud_shell_warning.PNG)  

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
![Cloud Shell properties](./images/step2_cloud_shell_properties.PNG)
 - Cliquer sur "create storage"

Une fois le Cloud Shell démarré, vous avez le choix entre une interface bash ou Powershell. Choisissez celle qui vous plait le plus. Cela n'a pas d'incidence sur l'usage d'az cli. Ici l'interface PowerShell
![Cloud Shell powershell](./images/step2_cloud_shell_powershell.PNG)  

> 👀 si vous utilisez az cli sur votre poste, bien vous authentifier sur Azure via la commande `az login` avant de suivre la suite de l'exercice

Configurer ensuite l'environnement de travail Azure à manipuler avec az cli :
 - Lister les souscriptions de votre abonnement : `az account show`
 - Choisir la souscriptions à manipuler : `az account set --subscription "XXXXX"` (où XXXXX = ID de votre souscription récupéré dans le résultat de la commande précédente)
  - A tout moment, pour une aide sur une commande `az XXX --help`(où XXX = commande sur laquelle obtenir de l'aide)

Ensuite, voici la commande à exécuter pour créer le Storage Account de cet exercice : `az storage account create --name dojoazureus01ex01 --resource-group dojoazure-us01-ex01 --location francecentral --https-only --kind StorageV2 --sku Standard_LRS --tags project=dojoazure,exercice=ex01,user=us01`
  
Quelques explications :
| Propriétés | Description | Valeur |
| --- | --- | --- |
| --name | Nom du Storage Account à créer | Ici `` (attention, nom unique pour la région)
| --resource-group | Nom du RG dans lequel créer le Storage Account | Ici `` (idem à l'étape 1 de cet exercice)
| --location | Région du Storage Account | Ici `francecentral`
| --https-only | Paramètre qui précise que le Storage Account ne sera utilisable qu'en https | 
| --kind | Paramètre pour préciser le type de Storage Account | Ici `StorageV2` qui indique la V2
| --sku | Paramètre pour préciser le SKU du Storage Account | Ici `Standard_LRS` qui indique que le storage sera de type Standard et en LRS ([cf. SKU Storage Account](#https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types))
| --tags | Région du Storage Account | Ici `project=dojoazure,exercice=ex01,user=us01` (idem aux tags utilisés pour la WebApp de l'étape 1)

> 👏 Bravo, votre Storage Account est créé !

## Etape 3 - Créer une base de données Azure SQL DB en utilisant un template ARM