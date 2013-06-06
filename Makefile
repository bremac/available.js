LESS = ./node_modules/less/
COFFEESCRIPT = ./node_modules/coffee-script/
TARGETS = available.css available.js

.PHONY: all clean

all: ${TARGETS}

${LESS}:
	npm install less

${COFFEESCRIPT}:
	npm install coffee-script

available.css: available.less
	${LESS}bin/lessc available.less available.css

available.js: available.coffee
	${COFFEESCRIPT}bin/coffee -c available.coffee
