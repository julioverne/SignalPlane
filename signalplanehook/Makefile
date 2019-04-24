include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SignalPlane
SignalPlane_OBJCC_FILES = /mnt/d/codes/signalplane/signalplanehook/Tweak.xm
SignalPlane_FRAMEWORKS = UIKit CydiaSubstrate CoreGraphics CoreTelephony AudioToolbox IOKit
SignalPlane_PRIVATE_FRAMEWORKS = Preferences
SignalPlane_CFLAGS = -fobjc-arc
SignalPlane_LDFLAGS = -Wl,-segalign,4000

export ARCHS = armv7 arm64
SignalPlane_ARCHS = armv7 arm64

include $(THEOS_MAKE_PATH)/tweak.mk
