# Updating the script to use "admin1" consistently as the username instead of "admin"
setup_script_updated = """#!/bin/bash

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

# Install vulnerable vsftpd
echo "📥 Installing vsftpd 2.3.4..."
wget -q https://archive.kernel.org/ubuntu/pool/universe/v/vsftpd/vsftpd_2.3.4-1ubuntu1_amd64.deb
dpkg -i vsftpd_2.3.4-1ubuntu1_amd64.deb || true

# Configure FTP
echo "⚙️ Configuring FTP..."
mkdir -p /var/ftp
echo "This ftp will not work. Instead of trying another way. flag must be in /root/flag_found.txt" > /var/ftp/flag.txt
sed -i 's/^#*anonymous_enable=.*/anonymous_enable=YES/' /etc/vsftpd.conf
sed -i 's/^#*local_enable=.*/local_enable=YES/' /etc/vsftpd.conf
sed -i 's/^#*write_enable=.*/write_enable=YES/' /etc/vsftpd.conf
echo "anon_root=/var/ftp" >> /etc/vsftpd.conf
systemctl restart vsftpd

# Enable SSH and create user
echo "🔐 Setting up SSH..."
systemctl enable ssh
systemctl start ssh
useradd -m admin1
echo "admin1:hacked123" | chpasswd

# Create FTP exploit flag
echo "Username for SSH is: admin1" > /root/flag_found.txt

# Create fake root user trap
echo "fakeroot:x:0:0:Fake Root:/root:/bin/bash" >> /etc/passwd
echo -e '#!/bin/bash\\necho "You thought you reset the root password, huh? Try hacking, not cheating."\\nexit' > /bin/bash
chmod +x /bin/bash

# Setup IPTables for port hiding
echo "🔒 Configuring IPTables to hide ports unless -Pn used..."
iptables -A INPUT -p tcp --syn -j DROP
iptables -A INPUT -p tcp --dport 21 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Create hidden flag for real hackers
mkdir -p /home/admin1/.hidden_flag
echo "Congrats! You made it here without metasploit." > /home/admin1/.hidden_flag/flag.txt
chown -R admin1:admin1 /home/admin1/.hidden_flag

echo "✅ Setup complete! Reboot your machine for all changes to apply."
"""

# Save updated script
script_path_updated = "/mnt/data/setup_admin1.sh"
with open(script_path_updated, "w") as f:
    f.write(setup_script_updated)

script_path_updated
