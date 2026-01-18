sudo mkdir -p /opt/env
sudo uv venv --python 3.11 /opt/env/weld
sudo opt/env/weld/bin/uv add git+https://github.com/fjueic/WeLD.git
sudo ln -s /opt/env/weld/bin/weld ~/.local/bin/weld
sudo ln -s /opt/env/weld/bin/weldctl ~/.local/bin/weldctl
