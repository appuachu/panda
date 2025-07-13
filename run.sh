#!/bin/bash

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
    sudo

# Configure vsftpd backdoor
echo "📥 Setting up vulnerable vsftpd..."
if [ ! -d "/tmp/vsftpd-backdoor" ]; then
    git clone https://github.com/DoctorKisow/vsftpd-2.3.4.git /tmp/vsftpd-backdoor
    cd /tmp/vsftpd-backdoor
    chmod +x vsf_findlibs.sh
    make || { echo "⚠️ Make failed - attempting to continue with system vsftpd"; apt-get install -y vsftpd; }
    if [ -f "vsftpd" ]; then
        mv /usr/sbin/vsftpd /usr/sbin/vsftpd.original
        cp vsftpd /usr/sbin/vsftpd
        cp vsftpd.conf /etc/
    fi
fi

# Configure FTP
echo "📁 Setting up FTP environment..."
mkdir -p /var/ftp
echo "Looking for flags? Try harder! The real flag is hidden elsewhere." > /var/ftp/readme.txt
chown nobody:nogroup /var/ftp
chmod a-w /var/ftp

# Setup SSH with weak credentials
echo "🔐 Configuring SSH with vulnerable settings..."
useradd -m -s /bin/bash admin5
echo "admin5:hacked123" | chpasswd
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
echo "root:toor" | chpasswd
echo "admin5 ALL=(ALL:ALL) ALL" >> /etc/sudoers
systemctl restart ssh

# Create flags
echo "🏴 Creating flag files..."
echo "flag{metasploit_was_here}" > /root/flag_found.txt
chmod 600 /root/flag_found.txt

mkdir -p /home/admin5/.hidden/.treasure
echo "flag{real_flag_hidden_here}" > /home/admin5/.hidden/.treasure/real_flag.txt
chown -R admin5:admin5 /home/admin5/.hidden
chmod -R 700 /home/admin5/.hidden

# Create SAFE bash trap that won't cause recursion
echo "🚧 Setting up SAFE root traps..."
cat > /bin/bash.trap <<'EOF'
#!/bin/bash.real
if [[ $EUID -ne 0 ]]; then
    # Allow sudo commands to pass through
    if [[ "$1" == "-c" ]]; then
        exec /bin/bash.real "$@"
    fi
    
    echo "Access denied. Try becoming root first."
    exit 1
fi

if [[ "$PWD" != "/root" && "$0" != "-bash" ]]; then
    echo "To navigate directories, you must solve the riddle:"
    echo "What has keys but can't open locks?"
    read -p "Answer: " answer
    if [[ "$answer" != "keyboard" ]]; then
        echo "Wrong! Staying in current directory."
        cd ~
    fi
fi

# Execute normally if all checks pass
exec /bin/bash.real "$@"
EOF

chmod +x /bin/bash.trap

# Backup real bash and replace SAFELY
if [ ! -f /bin/bash.real ]; then
    cp /bin/bash /bin/bash.real
fi
mv /bin/bash.trap /bin/bash

# Setup iptables
echo "🔒 Configuring IPTables..."
iptables -F
iptables -A INPUT -p tcp --dport 21 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP
iptables-save > /etc/iptables.rules
echo "iptables-restore < /etc/iptables.rules" >> /etc/rc.local
chmod +x /etc/rc.local

# Create emergency shell trap
echo "🛑 Creating emergency shell..."
cat > /tmp/emergency-shell <<'EOF'
#!/bin/bash.real
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
[ -f /bin/emergency-shell ] && mv /bin/emergency-shell /bin/emergency-shell.real
mv /tmp/emergency-shell /bin/emergency-shell

echo "✅ Setup complete! System will now reboot..."
reboot
