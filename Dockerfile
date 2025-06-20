ARG ROS_DISTRO=humble

FROM moveit/moveit2:${ROS_DISTRO}-release


ARG MUJOCO_VERSION=3.2.7
ARG CPU_ARCH=x86_64

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Configure base dependencies
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y python3-pip wget libglfw3-dev
RUN apt-get install -y python3-vcstool
RUN pip3 install xacro

# Configure and install MuJoCo
ENV MUJOCO_VERSION=${MUJOCO_VERSION}
ENV MUJOCO_DIR="/opt/mujoco/mujoco-${MUJOCO_VERSION}"
RUN mkdir -p ${MUJOCO_DIR}

RUN wget https://github.com/google-deepmind/mujoco/releases/download/${MUJOCO_VERSION}/mujoco-${MUJOCO_VERSION}-linux-${CPU_ARCH}.tar.gz
RUN mkdir -p /home/mujoco
RUN tar -xzf "mujoco-${MUJOCO_VERSION}-linux-${CPU_ARCH}.tar.gz" -C $(dirname "${MUJOCO_DIR}")

# Install existing src and dependencies
ENV ROS_WS="/home/ros2_ws/"
RUN mkdir -p ${ROS_WS}/src
WORKDIR ${ROS_WS}
COPY deps.repos .
RUN vcs import src < deps.repos
RUN rm deps.repos
RUN pip install mujoco

# Install ROS dependencies
RUN rosdep update && rosdep install --from-paths src/ --ignore-src -y
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ros-${ROS_DISTRO}-rqt \
    ros-${ROS_DISTRO}-rqt-common-plugins \
    ros-${ROS_DISTRO}-rqt-joint-trajectory-controller

# Compile
RUN . /opt/ros/${ROS_DISTRO}/setup.bash && \
    colcon build --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=ON

RUN echo 'source ${ROS_WS}/install/setup.bash' >> ~/.bashrc

CMD ["/bin/bash"]