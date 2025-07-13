#!/bin/bash

# Get the real path of the script and exit if called via symlink
SCRIPT_PATH=$(realpath -e "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
if [ -L "$0" ]; then
    echo "Error: Please execute the real script directly, not through a symbolic link" >&2
    echo "Real path: $SCRIPT_PATH" >&2
    exit 1
fi

# Exit on any error and show commands being executed
set -exo pipefail

echo "🔧 Setting up your custom vulnerable Linux environment..."

# Install essential packages first
echo "📦 Installing essential packages..."
apt-get update && apt-get install -y \
    build-essential \
    libpam0g-dev \
    git \
    vsftpd \
    openssh-server \
    iptables \
    gcc \
    make \
    net-tools \
    realpath

# Configure vsftpd backdoor
echo "📥 Setting up vulnerable vsftpd..."
if [ ! -d "/tmp/vsftpd-backdoor" ]; then
    git clone https://github.com/DoctorKisow/vsftpd-2.3.4.git /tmp/vsftpd-backdoor
    cd /tmp/vsftpd-backdoor || exit 1
    chmod +x vsf_findlibs.sh
    if ! make; then
        echo "⚠️ Make failed - attempting to continue with system vsftpd"
        apt-get install -y vsftpd
    else
        if [ -f "vsftpd" ]; then
            mv /usr/sbin/vsftpd /usr/sbin/vsftpd.original
            cp vsftpd /usr/sbin/vsftpd
            cp vsftpd.conf /etc/
        fi
    fi
fi

# Configure FTP
echo "📁 Setting up FTP environment..."
mkdir -p /var/ftp
echo "Looking for flags? Try harder! The real flag is hidden elsewhere. maybe user must admin1,2,3,4,5 password must superhardpassword123!" > /var/ftp/readme.txt
chown nobody:nogroup /var/ftp
chmod a-w /var/ftp

# Setup SSH with weak credentials
echo "🔐 Configuring SSH with vulnerable settings..."
if ! id admin4 &>/dev/null; then
    useradd -m -s /bin/bash admin4
fi
echo "admin4:hacked123" | chpasswd
sed -i 's/#PermitRootLogin prohibit-ssh/PermitRootLogin yes/' /etc/ssh/sshd_config
echo "root:toor" | chpasswd
systemctl restart ssh

# Create flags
echo "🏴 Creating flag files..."
echo "flag{metasploit_was_here}" > /root/flag_found.txt
chmod 600 /root/flag_found.txt

mkdir -p /home/admin4/.hidden/.treasure
echo "flag{real_flag_hidden_here}" > /home/admin4/.hidden/.treasure/real_flag.txt
chown -R admin4:admin4 /home/admin4/.hidden
chmod -R 700 /home/admin4/.hidden

# Create fake root trap
echo "🚧 Setting up root traps..."
cat > /tmp/bash.trap <<'EOF'
#!/bin/bash
if [[ $EUID -ne 0 ]]; then
    echo "Access denied. Try becoming root first."
    exit 1
fi

if [[ "$PWD" != "/root" ]]; then
    echo "To navigate directories, you must solve the riddle:"
    echo "What has keys but can't open locks?"
    read -p "Answer: " answer
    if [[ "$answer" != "keyboard" ]]; then
        echo "Wrong! Staying in current directory."
        cd ~
    fi
fi

# Execute real bash if all checks pass
exec /bin/bash.real "$@"
EOF

chmod +x /tmp/bash.trap

# Backup real bash and replace
if [ ! -f /bin/bash.real ]; then
    cp /bin/bash /bin/bash.real
    mv /tmp/bash.trap /bin/bash
fi

# Setup iptables to hide ports initially
echo "🔒 Configuring IPTables..."
iptables -F
iptables -A INPUT -p tcp --dport 21 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP
iptables-save > /etc/iptables.rules

# Make iptables persistent
echo "iptables-restore < /etc/iptables.rules" >> /etc/rc.local
chmod +x /etc/rc.local

# Protect against single user mode bypass
echo "🛡️ Hardening against bootloader attacks..."
if ! grep -q "restrict" /etc/default/grub; then
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=""/GRUB_CMDLINE_LINUX_DEFAULT="restrict"/' /etc/default/grub
    update-grub
fi

# Create a fake emergency shell that looks like root
echo "🛑 Creating emergency shell trap..."
cat > /tmp/emergency-shell <<'EOF'
#!/bin/bash
echo -n "Enter root password: "
read -s password
echo
if [[ "$password" != "superhardpassword123!" ]]; then
    echo "Access denied. All actions logged."
    logger "Unauthorized emergency shell access attempted"
    sleep 5
    exit 1
fi
exec /bin/bash.real
EOF

chmod +x /tmp/emergency-shell

# Replace normal emergency shell with our trapped version
if [ ! -f /bin/emergency-shell.real ]; then
    if [ -f /bin/emergency-shell ]; then
        mv /bin/emergency-shell /bin/emergency-shell.real
    fi
    mv /tmp/emergency-shell /bin/emergency-shell
fi

echo "✅ Setup complete! System will now reboot..."
reboot
