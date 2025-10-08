ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:13.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GlobalKeyboard

GlobalKeyboard_FILES = Tweak.xm GlobalKeyboardHelper.m
GlobalKeyboard_CFLAGS = -fobjc-arc
GlobalKeyboard_FRAMEWORKS = UIKit Foundation CoreGraphics
GlobalKeyboard_PRIVATE_FRAMEWORKS = SpringBoard
GlobalKeyboard_EXTRA_FRAMEWORKS = Cephei

include $(THEOS)/makefiles/tweak.mk
