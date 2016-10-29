# find toolchain path ($THEOS/toolchain/*/iphone, xcodebuild, /usr/bin)
# find sdk path ($THEOS/sdks, xcode)
# set target archs if not set already
# custom configuration stuff

if (NOT DEFINED ARCH)
    set(IOS_ARCH armv7 arm64)
endif()
