# find toolchain path ($THEOS/toolchain/*/iphone, xcodebuild, /usr/bin)
# find sdk path ($THEOS/sdks, xcode)
# set target archs if not set already
# custom configuration stuff

set(TOOLCHAIN_ROOT "$ENV{THEOS}/toolchain/linux/iphone")
set(SDK_ROOT "$ENV{THEOS}/sdks")


# cant find theos toolchain, search for toolchain with xcode
if (NOT EXISTS ${TOOLCHAIN_ROOT})
  execute_process(COMMAND xcodebuild -version
  OUTPUT_VARIABLE XCODE_VERSION
  ERROR_QUIET
  OUTPUT_STRIP_TRAILING_WHITESPACE)
  string(REGEX MATCH "Xcode [0-9\\.]+" XCODE_VERSION "${XCODE_VERSION}")
  string(REGEX REPLACE "Xcode ([0-9\\.]+)" "\\1" XCODE_VERSION "${XCODE_VERSION}")
  message(STATUS "Building with Xcode version: ${XCODE_VERSION}")
else()
  message(STATUS "Building with Theos")
endif()
#message(STATUS "${TOOLCHAIN_ROOT}")

# find sdks
if (NOT EXISTS ${SDK_ROOT})
  # we have some problems, search for xcode ones.
else()
  set(EXECUTE_FIND find ${SDK_ROOT})
  execute_process(COMMAND ${EXECUTE_FIND}
    OUTPUT_VARIABLE SDK_VERSION
    ERROR_QUIET
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  #message(STATUS "${SDK_VERSION}")
  string(REGEX MATCH "iPhoneOS[0-9\\.]+[0-3\\.]+[0-3\\.]+.sdk" SDK_VERSION "${SDK_VERSION}")
  message(STATUS "Building with SDK version ${SDK_VERSION}")
endif()

if (NOT DEFINED ARCH)
    set(IOS_ARCH armv7 arm64)
endif()

message(STATUS "Building for architectures ${IOS_ARCH}")
