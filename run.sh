# Full script with vulnerable vsftpd 2.3.4 backdoor install included

vsftpd_script = """#!/bin/bash

# Exit on any error
set -e

echo "🔧 Setting up your custom vulnerable Linux environment..."

# Disable apt
echo "⛔ Disabling apt..."
if [ -f /usr/bin/apt ]; then
    mv /usr/bin/apt /usr/bin/_apt_backup
    chmod 000 /usr/bin/_apt_backup
    echo -e '#!/bin/bash\\necho "apt is disabled. Try hacking instead."' > /usr/bin/apt
    chmod +x /usr/bin/apt
fi

# Remove dpkg and snap
rm -f /usr/bin/dpkg /usr/bin/snap || true

# Install build tools for vsftpd backdoor
echo "📥 Installing vulnerable vsftpd 2.3.4 backdoor..."
apt update && apt install -y build-essential libpam0g-dev git
git clone https://github.com/DoctorKisow/vsftpd-2.3.4.git /tmp/vsftpd-backdoor
cd /tmp/vsftpd-backdoor
chmod +x vsf_findlibs.sh
make || echo "⚠️ Make failed - check if pam is linked properly"
install -v -m 755 vsftpd /usr/sbin/vsftpd
install -v -m 644 vsftpd.conf /etc/vsftpd.conf
systemctl restart vsftpd

# Configure FTP root directory
mkdir -p /var/ftp
echo "This ftp will not work. Instead of trying another way. flag must be in /root/flag_found.txt" > /var/ftp/flag.txt

# Enable SSH and create user
echo "🔐 Setting up SSH..."
systemctl enable ssh
systemctl start ssh
useradd -m admin1
echo "admin1:hacked123" | chpasswd

# Create flag for metasploit
echo "Username for SSH is: admin1" > /root/flag_found.txt

# Create fake root trap
echo "fakeroot:x:0:0:Fake Root:/root:/bin/bash" >> /etc/passwd
echo -e '#!/bin/bash\\necho "You thought you reset the root password, huh? Try hacking, not cheating."\\nexit' > /bin/bash
chmod +x /bin/bash

# Setup IPTables to hide ports unless -Pn is used
echo "🔒 Configuring IPTables to hide ports unless -Pn used..."
iptables -A INPUT -p tcp --syn -j DROP
iptables -A INPUT -p tcp --dport 21 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Create hidden flag for smart attackers
mkdir -p /home/admin1/.hidden_flag
echo "Congrats! You made it here without metasploit." > /home/admin1/.hidden_flag/flag.txt
chown -R admin1:admin1 /home/admin1/.hidden_flag

echo "✅ Setup complete! Reboot your machine for all changes to apply."
"""

# Save the script
script_path = "/mnt/data/setup_vsftpd_admin1.sh"
with open(script_path, "w") as f:
    f.write(vsftpd_script)

script_path
