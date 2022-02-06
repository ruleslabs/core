SHEL							=	/bin/bash

CC								=	nile

SRCS_DIR					=	contracts/
SRCS_LIST					=	RulesTokens.cairo RulesCards.cairo RulesData.cairo
SRCS							=	$(addprefix $(SRCS_DIR), $(SRCS_LIST))

OBJS_DIR					=	artifacts/
OBJS_LIST					=	$(patsubst %.cairo, %.json, $(SRCS_LIST))
OBJS							=	$(addprefix $(OBJS_DIR), $(OBJS_LIST))

TESTS_DIR					= tests/
TESTS_BUILD_FLAGS = --cache-clear -s -W ignore::DeprecationWarning --asyncio-mode=auto
TESTS_FLAGS				= -W ignore::DeprecationWarning --asyncio-mode=auto -n 8

.PHONY : all clean

all : $(OBJS)

$(OBJS_DIR)%.json : $(SRCS_DIR)%.cairo
	@mkdir -p $(OBJS_DIR)
	@$(CC) compile $<

build-tests:
	@pytest $(TESTS_BUILD_FLAGS) $(TESTS_DIR)build_cache.py

run-tests:
	@pytest $(TESTS_FLAGS) $(TESTS_DIR)test.py

test: build-tests run-tests

clean :
	@$(CC) clean

re : clean all
