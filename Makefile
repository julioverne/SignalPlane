include $(THEOS)/makefiles/common.mk

SUBPROJECTS += signalplanehook
SUBPROJECTS += signalplanesettings

include $(THEOS_MAKE_PATH)/aggregate.mk

all::
	
