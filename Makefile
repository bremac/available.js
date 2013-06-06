LESS = ./node_modules/less/
COFFEESCRIPT = ./node_modules/coffee-script/
UGLIFYJS = ./node_modules/uglify-js/
CLEANCSS = ./node_modules/clean-css/

DEV_TARGETS = available.css available.js
MIN_TARGETS = available.min.css available.min.js

.PHONY: all clean distclean dev

all: ${DEV_TARGETS} ${MIN_TARGETS}

clean:
	rm -f ${DEV_TARGETS} ${MIN_TARGETS}

distclean: clean
	rm -rf ./node_modules/

dev: ${DEV_TARGETS}

${LESS}:
	npm install less

${COFFEESCRIPT}:
	npm install coffee-script

${UGLIFYJS}:
	npm install uglify-js

${CLEANCSS}:
	npm install clean-css

available.css: ${LESS} available.less
	${LESS}bin/lessc available.less available.css

available.js: ${COFFEESCRIPT} available.coffee
	${COFFEESCRIPT}bin/coffee -m -c available.coffee

available.min.css: ${CLEANCSS} available.css
	${CLEANCSS}bin/cleancss available.css -o available.min.css

available.min.js: ${UGLIFYJS} available.js
	${UGLIFYJS}bin/uglifyjs available.js -o available.min.js
