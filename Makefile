TARGET = anic.exe
INSTALL_PATH = /usr/bin

CFLAGS = -O3 -fomit-frame-pointer -ffast-math -pipe -Wall

TEST_FILES = tst/test.ani



### BUILD TYPES

main: start $(TARGET)

all: start cleanout test install

install: start $(TARGET)
	@echo Installing...
	@cp -f $(TARGET) $(INSTALL_PATH)/$(TARGET)
	@echo Done installing.

uninstall: start
	@echo Uninstalling...
	@rm -f $(INSTALL_PATH)/$(TARGET)

clean: start cleanout
	@echo Cleaning temporary files...
	@rm -R -f var
	@rm -R -f tmp

cleanout: start
	@echo Cleaning output...
	@rm -f $(TARGET)
	@rm -f tmp/version.exe
	@rm -f tmp/lexerStructGen.exe
	@rm -f tmp/parserStructGen.exe
	@make --directory=bld/hyacc --makefile=makefile clean -s

purge: start uninstall clean



### WRAPPER RULES

start:
	@echo anic ANI Compiler Makefile
	@echo

test: $(TARGET)
	@echo
	@echo ...Running default test cases...
	@echo --------------------------------
	./$(TARGET) -v $(TEST_FILES)
	@echo --------------------------------
	@echo Done running default test cases.



### BUILD AUXILIARIES

# VERSION CONTROLLER

tmp/version.exe: bld/version.c
	@echo Building version controller...
	@mkdir -p var
	@mkdir -p tmp
	@gcc bld/version.c -o tmp/version.exe
	
# LEXER

var/lexerStruct.h tmp/lexerStruct.o: tmp/lexerStructGen.exe src/lexerTable.txt src/lexer.h
	@echo Generating lexer structures...
	@mkdir -p var
	@./tmp/lexerStructGen.exe
	@echo Compiling lexer structure object...
	@mkdir -p tmp
	@g++ var/lexerStruct.cpp $(CFLAGS) -c -o tmp/lexerStruct.o

tmp/lexerStructGen.exe: bld/lexerStructGen.cpp
	@echo Building lexer structure generator...
	@mkdir -p tmp
	@g++ bld/lexerStructGen.cpp -o tmp/lexerStructGen.exe

# PARSER

var/parserStruct.h tmp/parserStruct.o: tmp/parserStructGen.exe var/parserTable.txt src/parser.h
	@echo Generating parser structure...
	@mkdir -p var
	@./tmp/parserStructGen.exe
	@echo Compiling parser structure object...
	@mkdir -p tmp
	@g++ var/parserStruct.cpp $(CFLAGS) -O1 -c -o tmp/parserStruct.o

tmp/parserStructGen.exe: bld/parserStructGen.cpp
	@echo Building parser structure generator...
	@mkdir -p tmp
	@g++ bld/parserStructGen.cpp -o tmp/parserStructGen.exe

tmp/hyacc.exe: bld/hyacc/makefile
	@echo Building parser table generator...
	@make --directory=bld/hyacc --makefile=makefile -s

var/parserTable.txt: tmp/hyacc.exe src/parserGrammar.y
	@echo Generating parser table...
	@./tmp/hyacc.exe -c -v -D1 -D2 -O1 -Q src/parserGrammar.y
	@mv y.output var/parserTable.txt



### CORE APPLICATION

$(TARGET): tmp/version.exe bld/hexTruncate.awk \
		src/mainDefs.h src/constantDefs.h src/system.h src/customOperators.h \
		src/lexer.h src/parser.h src/semmer.h \
		src/core.cpp src/system.cpp src/customOperators.cpp tmp/lexerStruct.o tmp/parserStruct.o src/lexer.cpp src/parser.cpp src/semmer.cpp
	@echo Building main executable...
	@g++ src/core.cpp src/system.cpp src/customOperators.cpp tmp/lexerStruct.o tmp/parserStruct.o src/lexer.cpp src/parser.cpp src/semmer.cpp \
	-D BUILD_NUMBER_MAIN="\"`./tmp/version.exe`\"" \
	-D BUILD_NUMBER_SUB="\"` date | shasum | awk -f bld/hexTruncate.awk `\"" \
	$(CFLAGS) \
	-static \
	-o $(TARGET)
	@echo Done building main executable.
