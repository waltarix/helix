ifeq ($(RUST_TARGET),)
	TARGET :=
	RELEASE_SUFFIX :=
else
	TARGET := $(RUST_TARGET)
	RELEASE_SUFFIX := -$(TARGET)
	export CARGO_BUILD_TARGET = $(RUST_TARGET)
endif

PROJECT_NAME := helix
BINARY_NAME  := hx

VERSION := $(file < VERSION)
RELEASE := $(PROJECT_NAME)-$(VERSION)$(RELEASE_SUFFIX)

DIST_DIR := dist
RELEASE_DIR := $(DIST_DIR)/$(RELEASE)
RUNTIME_DIR := $(RELEASE_DIR)/runtime
COMPLETION_DIR := $(RELEASE_DIR)/contrib/completion

BINARY := target/$(TARGET)/release/$(BINARY_NAME)

RELEASE_BINARY := $(RELEASE_DIR)/$(BINARY_NAME)
COMPLETION_FILES := $(addprefix $(COMPLETION_DIR)/, $(addprefix hx., bash fish zsh))

ARTIFACT := $(RELEASE).tar.xz

.PHONY: all
all: $(ARTIFACT)

$(BINARY):
	cargo build --locked --release

$(DIST_DIR) $(RELEASE_DIR) $(COMPLETION_DIR):
	mkdir -p $@

$(RELEASE_BINARY): $(BINARY) $(RELEASE_DIR)
	cp -f $< $@

$(ARTIFACT): $(RELEASE_BINARY) $(COMPLETION_FILES) $(RUNTIME_DIR)
	tar -C $(DIST_DIR) -Jcvf $@ $(RELEASE)

.PHONY: grammars
grammars: $(BINARY)

$(RUNTIME_DIR): grammars
	rsync -av --exclude grammars/sources/ runtime/ $@

$(COMPLETION_FILES): | $(COMPLETION_DIR)
	cp -f contrib/completion/$(@F) $@

.PHONY: clean
clean:
	$(RM) -r $(ARTIFACT) $(DIST_DIR)
