# # General Docker Setup Script
#
This Bash script automates the setup and management of a Docker-based environment tailored for web hosting and server administration. It configures essential services like **Portainer**, **Nginx**, **Nginx Proxy Manager**, **MariaDB**, **phpMyAdmin**, and **Duplicati** using Docker Compose, with a simple menu-driven interface.
#
# ## Features
 - **Fresh Setup**: Installs Docker and deploys all services from scratch.
 - **Repair**: Cleans up and redeploys containers to fix issues.
 - **Portainer Reset**: Resets Portainer data while keeping other services intact.
 - **Check & Update**: Pulls the latest images and redeploys services.
 - **Full Reset**: Wipes Docker completely and reinstalls everything.
 - **Environment Configuration**: Uses a `.env` file for customizable variables.
#
# ## Prerequisites
 - A Linux system (preferably Ubuntu/Debian-based).
 - Root or sudo privileges.
 - Internet connection for downloading Docker images.
#
# ## Getting Started
#
# ### 1. Clone the Repository
 ```bash
 git clone https://github.com/yourusername/mavedda-docker-setup.git
 cd mavedda-docker-setup
 ```
#
# ### 2. Make the Script Executable
 ```bash
 chmod +x setup.sh
 ```
#
# ### 3. Run the Script
 ```bash
 ./setup.sh
 ```
#
# ### 4. Configure the `.env` File
 The script checks for a `.env` file. If it doesn't exist, it creates a sample one with default values. Edit it to match your needs:
 ```bash
 DOMAIN="example.com"
 PORTAINER_ADMIN_NAME="admin"
 PORTAINER_PASSWORD="yourpassword"
 NETWORK_NAME="mavedda_network"
 NPM_ADMIN_NAME="admin@example.com"
 NPM_ADMIN_PASS="yourpassword"
 COMPOSE_DIR="/opt/docker/example.com"
 DB_MYSQL_USER="dbuser"
 DB_MYSQL_PASSWORD="dbpassword"
 DB_MYSQL_NAME="dbname"
 DUPLICATI_SECRET_KEY="yourkey"
 DUPLICATI_ADMIN_PASSWORD="duppassword"
 ```
#
# ### 5. Choose an Option
 The script presents a menu:
 1. **New Setup**: Installs Docker and deploys services.
 2. **Repair**: Fixes broken setups.
 3. **Reset Portainer**: Resets Portainer data.
 4. **Check and Update**: Updates images and services.
 5. **Full Reset**: Removes everything and reinstalls.
 6. **Exit**: Closes the script.
#
# ## Services Deployed
 - **Portainer**: Container management UI (port `9000`).
 - **Nginx**: Web server (port `8080`).
 - **Nginx Proxy Manager**: Reverse proxy with SSL support (ports `80`, `443`, `81`).
 - **MariaDB**: MySQL database (port `3306`).
 - **phpMyAdmin**: Database management UI (port `8183`).
 - **Duplicati**: Backup solution (port `8200`).
#
# ## Usage Notes
 - Ensure Docker is not already running if doing a fresh setup.
 - Check the output for IP-based access URLs and credentials after deployment.
 - Modify volume paths in the `docker-compose.yml` (e.g., Duplicati) as needed.
#
# ## Troubleshooting
 - If Docker fails to start, check logs with:
   ```bash
   systemctl status docker.service
   journalctl -xeu docker.service
   ```
 - Ensure all required variables are set in `.env`.
#
# ## Contributing
 Feel free to submit issues or pull requests to improve this script!
#
# ## License
 This project is licensed under the MIT License.
