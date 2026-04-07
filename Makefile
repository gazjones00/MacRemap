.PHONY: build release app clean install uninstall

build:
	swift build

release:
	swift build -c release

app:
	./scripts/build-app.sh

clean:
	swift package clean
	rm -rf .dist

install: app
	cp -R .dist/MacRemap.app /Applications/
	@echo "Installed to /Applications/MacRemap.app"

uninstall:
	rm -rf /Applications/MacRemap.app
	@echo "Removed /Applications/MacRemap.app"
