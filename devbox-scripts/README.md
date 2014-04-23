# How to install Murano devbox using packages

1. Prepare virtual machine with the following configuration
	* Ubuntu Server 12.04.4. x64
	* 1 NIC with Internet access

2. Install prerequisites
	```
	apt-get install git dpkg-dev
	```

3. Create folder for local packages
	```
	mkdir -p /opt/repo/murano
	cd /opt/repo/murano
	```

4. Copy .deb files into that folder

5. Create folder for git repositories
	```
	mkdir -p /opt/git
	cd /opt/git
	```

6. Clone repository with scripts and checkout required branch
	```
	git clone https://github.com/dmitry-teselkin/murano-deployment
	cd murano-deployment/devbox-scripts
	git checkout origin/devbox-scripts
	```

7. Add folder with local packages to the system repos
	```
	./devbox-manage add-local-repo /opt/repo/murano
	```

8. Edit murano installation config
	```
	vim muranorc
	```

9. Install Murano
	```
	./devbox-manage install-murano
	```

10. Open web browser and navigate to http://<your_vm_ip>/horizon Login with OpenStack credentials that are valid on the OpenStack host you've specified in muranorc.

11. Enjoy ;)
