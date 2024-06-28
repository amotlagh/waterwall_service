#!/bin/bash
echo "185.199.110.133 objects.githubusercontent.com" | sudo tee -a /etc/hosts > /dev/null
dic_path="$HOME/WaterWall/"
mkdir -p "$dic_path"
arch=$(uname -m)
latest_url_x64=$(curl -s https://api.github.com/repos/radkesvat/WaterWall/releases/latest | grep browser_download_url | grep 'Waterwall-linux-64.zip' | cut -d '"' -f 4)
latest_url_arm64=$(curl -s https://api.github.com/repos/radkesvat/WaterWall/releases/latest | grep browser_download_url | grep 'Waterwall-linux-arm64.zip' | cut -d '"' -f 4)
filename=""

if [ "$arch" = "x86_64" ]; then
    wget -P "$dic_path" "$latest_url_x64" && filename="Waterwall-linux-64.zip"
elif [ "$arch" = "aarch64" ]; then
    wget -P "$dic_path" "$latest_url_arm64" && filename="Waterwall-linux-arm64.zip"
else
    echo "Unsupported architecture."
    exit 1
fi

if [ -f "${dic_path}${filename}" ]; then
    sudo apt install unzip -y && unzip -o "${dic_path}${filename}" -d "$dic_path" && rm "${dic_path}${filename}"
    chmod +x "${dic_path}Waterwall"
else
    echo "Download failed."
    exit 1
fi

service_name="waterwall"
service_description="Waterwall Service"
service_documentation="https://github.com/radkesvat/WaterWall"
service_file="/etc/systemd/system/$service_name.service"
main_path="${dic_path}Waterwall"

read -r -d '' core_file <<EOF
{
  "log": {
    "path": "log/",
    "core": {
      "loglevel": "ERROR",
      "file": "core.log",
      "console": false
    },
    "network": {
      "loglevel": "ERROR",
      "file": "network.log",
      "console": false
    },
    "dns": {
      "loglevel": "SILENT",
      "file": "dns.log",
      "console": false
    }
  },
  "dns": {},
  "misc": {
    "workers": 0,
    "ram-profile": "server",
    "libs-path": "libs/"
  },
  "configs": ["config.json"]
}
EOF

echo "$core_file" | sudo tee "${dic_path}core.json" > /dev/null

cat > "$service_file" <<EOF
[Unit]
Description=$service_description
Documentation=$service_documentation
After=network.target nss-lookup.target

[Service]
ExecStart=$main_path
Restart=on-failure
WorkingDirectory=$dic_path

[Install]
WantedBy=multi-user.target
EOF

sudo chmod 644 "$service_file"
systemctl daemon-reload
sudo systemctl enable --now "$service_name.service"

echo "Service file created at: $service_file"
