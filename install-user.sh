mkdir -p ~/.local/share/env
uv venv --python 3.11 ~/.local/share/env/weld
~/.local/share/env/weld/bin/uv add git+https://github.com/fjueic/WeLD.git
ln -s ~/.local/share/env/weld/bin/weld ~/.local/bin/weld
ln -s ~/.local/share/env/weld/bin/weldctl ~/.local/bin/weldctl
