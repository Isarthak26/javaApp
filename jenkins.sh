#!/bin/bash

# Function to detect the OS
detect_os() {
  case "$(uname -s)" in
    Linux)
      if [[ -f /etc/debian_version ]]; then
        echo "debian"
      elif [[ -f /etc/redhat-release ]]; then
        echo "redhat"
      else
        echo "linux_unknown"
      fi
      ;;
    Darwin)
      echo "macos"
      ;;
    CYGWIN*|MINGW32*|MSYS*|MINGW*)
      echo "windows"
      ;;
    *)
      echo "unsupported"
      ;;
  esac
}

# Function to install Jenkins
install_jenkins() {
  local version=$1
  local os=$(detect_os)

  if [[ "$os" == "unsupported" ]]; then
    echo "Unsupported OS. This script supports Debian, RedHat-based systems, macOS, and Windows."
    exit 1
  fi

  echo "Detected OS: $os"
  echo "Installing Jenkins version $version..."

  case $os in
    debian)
      sudo apt update
      sudo apt install -y openjdk-11-jdk wget curl gnupg
      curl -fsSL https://pkg.jenkins.io/debian/jenkins.io.key | sudo tee /usr/share/keyrings/jenkins.asc
      echo "deb [signed-by=/usr/share/keyrings/jenkins.asc] https://pkg.jenkins.io/debian-stable/ stable main" | sudo tee /etc/apt/sources.list.d/jenkins.list
      sudo apt update
      sudo apt install -y jenkins="$version"
      ;;
    redhat)
      sudo yum install -y java-11-openjdk wget curl
      sudo curl -fsSL https://pkg.jenkins.io/redhat/jenkins.repo -o /etc/yum.repos.d/jenkins.repo
      sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key
      sudo yum install -y jenkins-"$version"
      ;;
    macos)
      if ! command -v brew &>/dev/null; then
        echo "Homebrew is not installed. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi
      brew install openjdk@11
      brew install jenkins-lts@$version
      ;;
    windows)
      echo "Installing Jenkins on Windows..."
      # Windows installation steps:
      # 1. Download Jenkins MSI Installer
      curl -Lo jenkins.msi https://get.jenkins.io/war-stable/$version/jenkins.msi
      # 2. Install the MSI package
      start /wait msiexec /i jenkins.msi /quiet /norestart
      ;;
  esac

  # Start Jenkins
  echo "Starting Jenkins..."
  if [[ "$os" == "debian" || "$os" == "redhat" ]]; then
    sudo systemctl enable --now jenkins
  elif [[ "$os" == "macos" ]]; then
    brew services start jenkins-lts
  elif [[ "$os" == "windows" ]]; then
    # Windows Jenkins should automatically start as a service
    echo "Jenkins installed and started as a service."
  fi

  echo "Jenkins installation completed. Access it at http://localhost:8080"
}

# Main Script
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <jenkins_version>"
  exit 1
fi

JENKINS_VERSION=$1
install_jenkins "$JENKINS_VERSION"

