ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:16.0
INSTALL_TARGET_PROCESSES = WeChat Preferences

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = KeyBoardModule

KeyBoardModule_FILES = Tweak.xm
KeyBoardModule_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 WeChat || true"
