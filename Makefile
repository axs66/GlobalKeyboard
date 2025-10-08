ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GlobalKeyboard

GlobalKeyboard_FILES = Tweak.xm GlobalKeyboardHelper.m
GlobalKeyboard_CFLAGS = -fobjc-arc
GlobalKeyboard_FRAMEWORKS = UIKit Foundation CoreGraphics
GlobalKeyboard_LDFLAGS = -Wl,-undefined,dynamic_lookup

include $(THEOS)/makefiles/tweak.mk
