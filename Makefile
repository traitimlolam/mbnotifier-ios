TARGET := iphone:clang:latest:15.0
ARCHS := arm64e
INSTALL_TARGET_PROCESSES := SpringBoard

THEOS_PACKAGE_SCHEME := roothide
FINALPACKAGE := 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := MBNotifier
MBNotifier_FILES := Tweak.x
MBNotifier_CFLAGS := -fobjc-arc -Wno-error

include $(THEOS_MAKE_PATH)/tweak.mk
