# oracle-liquibase

Sample of using LiquidBase with Oracle database and Jenkins pipeline

# WORK IN PROGRESS
BE AWARE: A LOT OF HARDCODED PARAMETERS!

## Install dependencies
The following dependencies has to be intalled prior the sample. 
We recommend always to use a package manager.

In our case, we are using MacOS and Homebrew as package manager, so the installation commans will use this.
### Java
* Check your installed java version. this sample requires Java 11 or later
* Download the JDBC drivers maching the Java version and the Oracle Database version used. In this sample we are using openjdk@11 and Autonomous Database for JSON, currently using 19c. So, dowload ojdbc10 version from [here](https://www.oracle.com/database/technologies/appdev/jdbc-ucp-19-10-c-downloads.html)
### Gradle
* [Download your Gradle flavor](https://gradle.org/install/) 

  MacOS
  ```
  brew install gradle
  ```

### Jenkins
* [Download your Jenkins flavor](https://www.jenkins.io/download/)

  OSX Homebrew
  ```
  brew install jenkins-lts
  brew services start jenkins-lts
  ```
* Configure
  Get generated admin password from user home directory
  ```
  cat ~/.jenkins/secrets/initialAdminPassword
  ```

* Connect to http://localhost:8080 to end configuration. Paste the admin password, and select initial set of plugins
* Create administrator user and password. Optionally, set the e-mail address
* Set the Jenkins URL. Notice: The change in MacOS can be a little tricky, check this [StackOverflow post](https://stackoverflow.com/questions/7139338/change-jenkins-port-on-macos)

### Springboot CLI
* [Install SpringBoot client](https://docs.spring.io/spring-boot/docs/current/reference/html/getting-started.html#getting-started-installing-spring-boot)

  OSX Homebrew
```
brew tap spring-io/tap
brew install spring-boot
```

### LiquidBase
* [Install your Liquibase CLI flavor](https://www.liquibase.org/download)

  OSX Homebrew
```
brew install gcc
brew install liquibase
liquibase --help
```
* [Download the Oracle JDBC drivers version 10](https://www.oracle.com/database/technologies/appdev/jdbc-downloads.html) and copy to liquibase lib directory. NOTICE: Use jdbc10 drivers, jdbc8 does not work!!!
  OSX Homebrew
```
cd /usr/local/Cellar/liquibase/4.3.4/libexec/lib
cp ~/Downloads/ojdbc8-full.tar.gz .
tar -xvzf ojdbc10-full.tar.gz
mv OJDBC8-Full/* .
rm -rf OJDBC8-Full/
```



## Build application sample (version 1)
### Provision an OCI Autonomous Database
OCI Autonomous Database (henceforth ADB) can be provisioned using the [oci console](https://cloud.oracle.com) or oci cli commands.
You will need the following parameters:
* Optional: If you use several profiles for OCI (e.g., you manage several accounts, ensure you know the name and use the correct --profile command line option)
* Compartment OCID: If required and you are allowed, create a comparment for this test. 

  If not, ask you OCI administrator for a compartment ID
* DB admin password: As we are going to expose this database to public internet choose wisely!


Using OCI CLI, you can create the autonomous database as

ocid1.compartment.oc1..aaaaaaaadanfxejgerljyzontldg275quuf4sdc4pel52z67f64nas7xrm5q


```
oci db autonomous-database create \
	--profile EMEASPAINSANDBOX \
	--compartment-id ocid1.compartment.oc1..aaaaaaaadanfxejgerljyzontldg275quuf4sdc4pel52z67f64nas7xrm5q \
	--cpu-core-count 1 \
	--data-storage-size-in-tbs 1 \
	--db-name lbtest \
	--admin-password 1UPPERCASE#1lowercase \
	--db-version 19c \
	--db-workload AJD \
	--display-name "LiquidBase sample database" \
	--license-model LICENSE_INCLUDED \
	--wait-for-state AVAILABLE
```

After creation, download the wallet for connection
```
export ADB_ID=$(oci db autonomous-database list \
	--profile EMEASPAINSANDBOX \
	--compartment-id ocid1.compartment.oc1..aaaaaaaadanfxejgerljyzontldg275quuf4sdc4pel52z67f64nas7xrm5q \
	--display-name "LiquidBase sample database" \
	|jq -r ".data[0].id")

oci db autonomous-database generate-wallet \
	--profile EMEASPAINSANDBOX \
	--autonomous-database-id $ADB_ID \
	--password 1UPPERCASE#1lowercase \
	--file keystore/wallet.zip \
	--generate-type SINGLE 
```

And uncompress the wallet in 2 well-known directory
* First will be used to connect from the application
* Second will be used to connecto from the liquibase client

### Create a SpringBoot sample project
* Create an empty SpringBoot project, using the [initializr](https://start.spring.io/) wizard or directly using `spring init` command.
* Add dependencies for web management, persistence,oracle database drivers and actuator (web,data-jpa,oracle,actuator,validation,devtools)

```
spring init --build=gradle --dependencies=web,data-jpa,oracle,actuator,validation,devtools  application
```

* Edit `build.gradle` generated file, and add oracle drivers additiinal depedencies (ojdbc8 artifact has to be already there)
```
// Oracle Database Drivers
implementation 'com.oracle.database.jdbc:ojdbc8'
implementation 'com.oracle.database.jdbc:ucp'	
implementation 'com.oracle.database.security:oraclepki'
implementation 'com.oracle.database.security:osdt_cert'
implementation 'com.oracle.database.security:osdt_core'
```

* Add a Oracle Datasource Configuration bean (see code in repository)

* Add an entity POJO class, mapping the PRODUCT table (see code in repository)

* Add a CRUD repository interfaces for finding and delete by primary key  in Product Entity (see code in repository)

* Add a controller for read, create and delete product (see code in repository)

* Edit the application properties file, and set url (pointing to the wallet), user, password and oracle hibernate dialect (see code in repository)
  * Check the URL: The name is based in dbname + service level, and the address of the wallet is relative to execution directoy. Remember we are using 2 copies of wallet: Use the copy correponding to application (copy uncompressed and unedited)

### Liquibase
* Check the instruction to connect to [Oracle Autonomous Database](https://docs.liquibase.com/workflows/database-setup-tutorials/oracle-atp-db.html)
* Edit the second wallet copy and edit:
  * The `ojdbc.properties` file
	  * Uncomment the javax.net.ssl properties lines
		* Comment out the oracle.net.wallet_location line.
		* Set javax.net.ssl.trustStorePassword to the wallet password (notice that this is the [admin-password](#provision-an-oci-autonomous-database) assigned to wallet when you downloaded)
		* Set javax.net.ssl.keyStorePassword to the wallet password. (notice that this is the [admin-password](#provision-an-oci-autonomous-database)
	* Check the `sqlnet.ora` file
		* Parameter `SSL_SERVER_DN_MATCH=yes`
* Generate the project folder structure
```
  mkdir <myproject>/database
	mkdir <myproject>/database/changelogs
	mkdir <myproject>/database/scripts
```

* Copy
* Create a master change log file with `changelog_master.xml` in changelogs
```
<?xml version="1.0" encoding="UTF-8"?> 
<databaseChangeLog
  xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
                      http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-3.9.xsd">

</databaseChangeLog>
```











