FORGE_MAKEFILE_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
include $(FORGE_MAKEFILE_DIR)misc.mk
include $(FORGE_MAKEFILE_DIR)python.mk
include $(FORGE_MAKEFILE_DIR)database.mk
include $(FORGE_MAKEFILE_DIR)geo.mk
