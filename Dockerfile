FROM nvidia/cuda:11.3.0-devel-ubuntu20.04

ENV CUDAARCHS="60"
ENV TRIMESH_VERSION="2020.03.04"
ENV CMAKE_VERSION="3.20.4"

# Install GLM, OpenMP and other libraries
RUN apt update && \
    apt install -y --no-install-recommends apt-utils && \
    apt install -y libglm-dev libgomp1 git mesa-common-dev libglu1-mesa-dev libxi-dev wget ninja-build

# Install CMake
RUN wget -q -O ./cmake-install.sh https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh && \
    chmod u+x ./cmake-install.sh && \
    mkdir "$HOME"/cmake && \
    ./cmake-install.sh --skip-license --prefix="$HOME"/cmake && \
    rm ./cmake-install.sh

# Build Trimesh2
RUN git clone --single-branch --depth 1 -b ${TRIMESH_VERSION} https://github.com/Forceflow/trimesh2.git ../trimesh2 && \
    cd ../trimesh2 && \
    make all -j $(nproc) && \
    make clean

WORKDIR /cuda_voxelizer
COPY . .

# Configure cuda_voxelizer
RUN PATH=$PATH:"$HOME"/cmake/bin cmake -GNinja \
        -DTrimesh2_INCLUDE_DIR="../trimesh2/include" \
        -DTrimesh2_LINK_DIR="../trimesh2/lib.Linux64" \
        -S . -B ./build

# Build cuda_voxelizer
RUN PATH=$PATH:"$HOME"/cmake/bin cmake --build ./build --parallel $(nproc)

# Test
RUN ./build/cuda_voxelizer -f ./test_models/bunny.OBJ -s 64 -cpu

ENTRYPOINT ["./build/cuda_voxelizer"]
