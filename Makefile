export THEOS_PACKAGE_SCHEME = rootless
export TARGET = iphone:clang:16.5:15.0
export ARCHS = arm64
export STRIP = :

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = QuickTranslate

QuickTranslate_FILES = Tweak.x
QuickTranslate_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
QuickTranslate_LDFLAGS = -fuse-ld=lld
QuickTranslate_FRAMEWORKS = UIKit Foundation
QuickTranslate_EXTRA_FRAMEWORKS = CydiaSubstrate

include $(THEOS_MAKE_PATH)/tweak.mk

after-QuickTranslate-stage::
	$(ECHO_NOTHING)plutil -convert binary1 $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/QuickTranslate.plist 2>/dev/null || true$(ECHO_END)
