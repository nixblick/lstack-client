cmake_minimum_required(VERSION 3.20)
project(lstack-client VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.2 COMPONENTS Core Gui Qml Quick QuickControls2 REQUIRED)

qt_add_executable(lstack-client
    src/main.cpp
)

qt_add_qml_module(lstack-client
    URI LSTack
    VERSION 1.0
    RESOURCE_PREFIX /
    QML_FILES
        ui/Main.qml
        ui/components/TopBar.qml
        ui/components/StatusBar.qml
    RESOURCES
        resources/icons/lstack-client.png
    NO_RESOURCE_TARGET_PATH
)

set_target_properties(lstack-client PROPERTIES
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE FALSE
)

target_link_libraries(lstack-client
    PRIVATE
        Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::QuickControls2
)

install(TARGETS lstack-client RUNTIME DESTINATION bin)
