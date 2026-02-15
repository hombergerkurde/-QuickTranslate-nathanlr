export THEOS_PACKAGE_SCHEME = rootless
export TARGET = iphone:clang:16.5:15.0
export ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = QuickTranslate

QuickTranslate_FILES = Tweak.x
QuickTranslate_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
QuickTranslate_FRAMEWORKS = UIKit Foundation
QuickTranslate_EXTRA_FRAMEWORKS = CydiaSubstrate
QuickTranslate_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

include $(THEOS_MAKE_PATH)/tweak.mk
