# find toolchain path ($THEOS/toolchain/*/iphone, xcodebuild, /usr/bin)
# find sdk path ($THEOS/sdks, xcode)
# set target archs if not set already
# custom configuration stuff

set(TOOLCHAIN_ROOT "$ENV{THEOS}/toolchain/linux/iphone")
set(SDKS_ROOT "$ENV{THEOS}/sdks")

if (NOT DEFINED IOS_ARCH)
    set(IOS_ARCH armv7 arm64)
endif()

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
  if (NOT CMAKE_C_COMPILER)
      file(GLOB CLANG_LOC "${TOOLCHAIN_ROOT}/bin/*clang")
      set(CMAKE_C_COMPILER ${CLANG_LOC})
      message(STATUS "Using C compiler: ${CMAKE_C_COMPILER}")
 endif()
 if (NOT CMAKE_CXX_COMPILER)
     file(GLOB CLANGXX_LOC "${TOOLCHAIN_ROOT}/bin/*clang++")
     set(CMAKE_CXX_COMPILER ${CLANGXX_LOC})
     message(STATUS "Using CXX compiler: ${CMAKE_CXX_COMPILER}")
  endif()
  set(IOS_LIBTOOL GLOB "${TOOLCHAIN_ROOT}/bin/*libtool")
  set(CMAKE_C_CREATE_STATIC_LIBRARY
    "${IOS_LIBTOOL} -static -o <TARGET> <LINK_FLAGS> <OBJECTS> ")
  set(CMAKE_CXX_CREATE_STATIC_LIBRARY
    "${IOS_LIBTOOL} -static -o <TARGET> <LINK_FLAGS> <OBJECTS> ")
endif()

#message(STATUS "${TOOLCHAIN_ROOT}")

# find sdks
if (NOT EXISTS ${SDKS_ROOT})
  # we have some problems, search for xcode ones.
else()
  set(EXECUTE_FIND find ${SDKS_ROOT})
  execute_process(COMMAND ${EXECUTE_FIND}
    OUTPUT_VARIABLE SDK_VERSION
    ERROR_QUIET
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  #message(STATUS "${SDK_VERSION}")
  string(REGEX MATCH "iPhoneOS[0-9\\.]+[0-3\\.]+[0-3\\.]+.sdk" SDK_VERSION "${SDK_VERSION}")
  message(STATUS "Building with SDK version ${SDK_VERSION}")
endif()

set(SDK_ROOT "${SDKS_ROOT}/${SDK_VERSION}")

set(CMAKE_SYSROOT ${SDK_ROOT})
set(CMAKE_OSX_SYSROOT ${SDK_ROOT})

set(UNIX TRUE)
#set(APPLE TRUE)
#set(IOS TRUE)

set(CMAKE_OSX_DEPLOYMENT_TARGET "" CACHE STRING
  "Must be empty for iOS builds." FORCE)
# Set the architectures for which to build.
set(CMAKE_OSX_ARCHITECTURES ${IOS_ARCH} CACHE STRING "Build architecture for iOS")
# Skip the platform compiler checks for cross compiling.
set(CMAKE_CXX_COMPILER_FORCED TRUE)
set(CMAKE_CXX_COMPILER_WORKS TRUE)
set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_C_COMPILER_WORKS TRUE)

set(CMAKE_SHARED_LIBRARY_PREFIX "lib")
set(CMAKE_SHARED_LIBRARY_SUFFIX ".dylib")
set(CMAKE_SHARED_MODULE_PREFIX "lib")
set(CMAKE_SHARED_MODULE_SUFFIX ".so")
set(CMAKE_MODULE_EXISTS 1)
set(CMAKE_DL_LIBS "")
set(CMAKE_C_OSX_COMPATIBILITY_VERSION_FLAG "-compatibility_version ")
set(CMAKE_C_OSX_CURRENT_VERSION_FLAG "-current_version ")
set(CMAKE_CXX_OSX_COMPATIBILITY_VERSION_FLAG "${CMAKE_C_OSX_COMPATIBILITY_VERSION_FLAG}")
set(CMAKE_CXX_OSX_CURRENT_VERSION_FLAG "${CMAKE_C_OSX_CURRENT_VERSION_FLAG}")

set(IOS_DEPLOYMENT_TARGET "${SDK_VERSION}" CACHE STRING "Minimum iOS version to build for." )

set(IOS_PLATFORM_VERSION_FLAGS "-mios-version-min=6.0") #TODO variable here

set(CMAKE_C_FLAGS "${IOS_PLATFORM_VERSION_FLAGS} -fobjc-abi-version=2 -isysroot ${SDK_ROOT} -fobjc-arc ${CMAKE_C_FLAGS}")
set(CMAKE_CXX_FLAGS "${IOS_PLATFORM_VERSION_FLAGS} -fvisibility=hidden -isysroot ${SDK_ROOT} -fvisibility-inlines-hidden -fobjc-abi-version=2 -fobjc-arc ${CMAKE_CXX_FLAGS}")

set(CMAKE_CXX_FLAGS_RELEASE "-DNDEBUG -O3 -fomit-frame-pointer -ffast-math ${CMAKE_CXX_FLAGS_RELEASE}")
set(CMAKE_C_LINK_FLAGS "${IOS_PLATFORM_VERSION_FLAGS} -Wl,-search_paths_first ${CMAKE_C_LINK_FLAGS}")
set(CMAKE_CXX_LINK_FLAGS "${IOS_PLATFORM_VERSION_FLAGS}  -Wl,-search_paths_first ${CMAKE_CXX_LINK_FLAGS}")

message(STATUS "Building for architectures ${IOS_ARCH}")

# In order to ensure that the updated compiler flags are used in try_compile()
# tests, we have to forcibly set them in the CMake cache, not merely set them
# in the local scope.
list(APPEND VARS_TO_FORCE_IN_CACHE
  CMAKE_C_FLAGS
  CMAKE_CXX_FLAGS
  CMAKE_CXX_RELEASE
  CMAKE_C_LINK_FLAGS
  CMAKE_CXX_LINK_FLAGS)
foreach(VAR_TO_FORCE ${VARS_TO_FORCE_IN_CACHE})
  set(${VAR_TO_FORCE} "${${VAR_TO_FORCE}}" CACHE STRING "" FORCE)
endforeach()

set(CMAKE_PLATFORM_HAS_INSTALLNAME 1)
set(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS "-dynamiclib -headerpad_max_install_names")
set(CMAKE_SHARED_MODULE_CREATE_C_FLAGS "-bundle -headerpad_max_install_names")
set(CMAKE_SHARED_MODULE_LOADER_C_FLAG "-Wl,-bundle_loader,")
set(CMAKE_SHARED_MODULE_LOADER_CXX_FLAG "-Wl,-bundle_loader,")
set(CMAKE_FIND_LIBRARY_SUFFIXES ".dylib" ".so" ".a")

# Hack: if a new cmake (which uses CMAKE_INSTALL_NAME_TOOL) runs on an old
# build tree (where install_name_tool was hardcoded) and where
# CMAKE_INSTALL_NAME_TOOL isn't in the cache and still cmake didn't fail in
# CMakeFindBinUtils.cmake (because it isn't rerun) hardcode
# CMAKE_INSTALL_NAME_TOOL here to install_name_tool, so it behaves as it did
# before, Alex.
# if (NOT DEFINED CMAKE_INSTALL_NAME_TOOL)
#   find_program(CMAKE_INSTALL_NAME_TOOL install_name_tool)
# endif (NOT DEFINED CMAKE_INSTALL_NAME_TOOL)

set(CMAKE_FIND_FRAMEWORK FIRST)

set(CMAKE_SYSTEM_FRAMEWORK_PATH
  ${SDK_ROOT}/System/Library/Frameworks
  ${SDK_ROOT}/System/Library/PrivateFrameworks
  ${SDK_ROOT}/Developer/Library/Frameworks)

# Only search the specified iOS SDK, not the remainder of the host filesystem.
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
