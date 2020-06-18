SHELL = /bin/bash
APPNAME = slack-calendar-status
APPBUNDLE = $(APPNAME).app
SOURCES = $(wildcard Sources/**/*.swift)

.DEFAULT_GOAL = bundle

.PHONY: bundle
bundle: $(SOURCES)
	@swift build
	@rm -rf $(APPBUNDLE)
	@mkdir -p $(APPBUNDLE)/Contents/MacOS
	@cp Info.plist $(APPBUNDLE)/Contents
	@cp .build/debug/$(APPNAME) $(APPBUNDLE)/Contents/MacOS
