# General Docker Setup Script

This Bash script automates the setup and management of a Docker-based environment tailored for web hosting and server administration. It configures essential services like **Portainer**, **Nginx**, **Nginx Proxy Manager**, **MariaDB**, **phpMyAdmin**, and **Duplicati** using Docker Compose, with a simple menu-driven interface.

## Features
- **Fresh Setup**: Installs Docker and deploys all services from scratch.
- **Repair**: Cleans up and redeploys containers to fix issues.
- **Portainer Reset**: Resets Portainer data while keeping other services intact.
- **Check & Update**: Pulls the latest images and redeploys services.
- **Full Reset**: Wipes Docker completely and reinstalls everything.
- **Environment Configuration**: Uses a `.env` file for customizable variables.

## Prerequisites
- A Linux system (preferably Ubuntu/Debian-based).
- Root or sudo privileges.
- Internet connection for downloading Docker images.

## Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/hidirektor/general_launcher.git
cd mavedda-docker-setup
