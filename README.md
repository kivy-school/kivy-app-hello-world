
create .venv by
```
uv sync
```

make build-wheels executable
```
chmod -x build-wheels.sh
```

build custom wheels for local wheels/simple
```
./build-wheels.sh
```

update simple index
```
uv update simple
```

update xcode project site-packages
```
uv run psproject update site-packages
```

run on desktop (normal uv desktop mode)
```
uv run HelloWorld
```

open xcode project and set developer id

# run xcode project without having to launch xcode
!!! warning Xcode.app is still required to be installed

simulator
```
uv run ps-launcher sim DEVICE-UUID
```

iphone or ipad
```
uv run ps-launcher ios DEVICE-UUID
```

!!! info get device uuid
```
xcrun xctrace list devices
```
result:
```
== Devices ==
My Mac Pro (AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE)
My iPad Pro (26.3) (00001234-ABCDEF1234560000)

== Simulators ==
iPad Pro (11-inch) (4th generation) Simulator (26.2) (12345678-ABCD-1234-ABCD-123456789ABC)
iPhone 16e Simulator (26.2) (87654321-DCBA-4321-DCBA-CBA987654321)
```