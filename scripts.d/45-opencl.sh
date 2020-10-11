#!/bin/bash

HEADERS_REPO="https://github.com/KhronosGroup/OpenCL-Headers.git"
HEADERS_COMMIT="b316a57d5b8e3ae4a19c3b344c52ba86a4b7e790"

LOADER_REPO="https://github.com/KhronosGroup/OpenCL-ICD-Loader.git"
LOADER_COMMIT="b3b483303b160db080857288c1b53e8152f62b98"

ffbuild_enabled() {
    return 0
}

ffbuild_dockerstage() {
    to_df "ADD $SELF /stage.sh"
    to_df "RUN run_stage"
}

ffbuild_dockerbuild() {
    mkdir opencl && cd opencl

    git-mini-clone "$HEADERS_REPO" "$HEADERS_COMMIT" headers
    mkdir -p "$FFBUILD_PREFIX"/include/CL
    cp -r headers/CL/* "$FFBUILD_PREFIX"/include/CL/.

    git-mini-clone "$LOADER_REPO" "$LOADER_COMMIT" loader
    cd loader

    mkdir build && cd build

    cmake -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX" -DOPENCL_ICD_LOADER_HEADERS_DIR="$FFBUILD_PREFIX"/include -DBUILD_SHARED_LIBS=OFF -DOPENCL_ICD_LOADER_DISABLE_OPENCLON12=ON -DOPENCL_ICD_LOADER_PIC=ON -DOPENCL_ICD_LOADER_BUILD_TESTING=OFF ..
    make -j$(nproc)
    make install

    echo "prefix=$FFBUILD_PREFIX" > OpenCL.pc
    echo "exec_prefix=\${prefix}" >> OpenCL.pc
    echo "libdir=\${exec_prefix}/lib" >> OpenCL.pc
    echo "includedir=\${prefix}/include" >> OpenCL.pc
    echo >> OpenCL.pc
    echo "Name: OpenCL" >> OpenCL.pc
    echo "Description: OpenCL ICD Loader" >> OpenCL.pc
    echo "Version: 9999" >> OpenCL.pc
    echo "Libs: -L\${libdir} -lOpenCL" >> OpenCL.pc
    echo "Libs.private: -lole32 -lshlwapi -lcfgmgr32" >> OpenCL.pc
    echo "Cflags: -I\${includedir}" >> OpenCL.pc

    mkdir -p "$FFBUILD_PREFIX"/lib/pkgconfig
    mv OpenCL.pc "$FFBUILD_PREFIX"/lib/pkgconfig/OpenCL.pc

    cd ../../..
    rm -rf opencl
}

ffbuild_configure() {
    echo --enable-opencl
}

ffbuild_unconfigure() {
    echo --disable-opencl
}
