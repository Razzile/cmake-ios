# find toolchain path ($THEOS/toolchain/*/iphone, xcodebuild, /usr/bin)
# find sdk path ($THEOS/sdks, xcode)
# set target archs if not set already
# custom configuration stuff

set(TOOLCHAIN_ROOT GLOB "$ENV{THEOS}/toolchain/*/iphone")



# cant find theos toolchain, search for toolchain with xcode
if (NOT EXISTS ${TOOLCHAIN_ROOT})
    
endif()

if (NOT DEFINED ARCH)
    set(IOS_ARCH armv7 arm64)
endif()
