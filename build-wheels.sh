ARCH=$1

WHEEL_OUTPUT_DIR="$PWD/wheels"
cd wheel_sources

# build kivy from master branch to get the latest build
./kivy_wheels.sh $ARCH $WHEEL_OUTPUT_DIR

# build kivymd 1.2.0 wheel since it has issues with uv sync and needs to be built from source
./kivy_md_wheel.sh