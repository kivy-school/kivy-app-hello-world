
#cd wheel_sources

# Download source distribution for the package
uv run pip3 download kivymd==1.2.0 --no-deps -d .

uv build kivymd-1.2.0.tar.gz --wheel -o ../wheels