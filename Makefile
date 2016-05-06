.PHONY: all get-deps clean compile run eunit check check-eunit doc

# determine which Rebar we want to be running
REBAR2=$(shell which rebar || echo ./rebar)
REBAR3=$(shell which rebar3)
ifeq ($(FORCE_REBAR2),true)
 REBAR=$(REBAR2)
 REBAR_VSN=2
else ifeq ($(REBAR3),)
 REBAR=$(REBAR2)
 REBAR_VSN=2
else
 REBAR=$(REBAR3)
 REBAR_VSN=3
endif

# eventually this should be just ebin/*.beam, but there are a number
# of warnings in other files. Just check the clean files for now.
CHECK_FILES=\
	ebin/*.beam

# Checks on the eunit files can help find bad specs and other issues,
# however there are some expected errors in some of the exception
# tests that should be ignored.
CHECK_EUNIT_FILES=\
	$(CHECK_FILES)


all: get-deps compile

get-deps:
ifeq ($(REBAR_VSN),2)
	@$(REBAR) get-deps
endif

clean:
	@$(REBAR) clean

compile:
	@$(REBAR) compile

run:
ifeq ($(REBAR_VSN),2)
	erl -pa deps/*/ebin -pa ./ebin
else
	$(REBAR) shell
endif

eunit:
ifeq ($(REBAR_VSN),2)
	@$(REBAR) compile
	@$(REBAR) eunit skip_deps=true
else
	@$(REBAR) eunit
endif

check:
ifeq ($(REBAR_VSN),2)
	@$(REBAR) compile
	dialyzer --verbose --no_check_plt --no_native --fullpath \
		$(CHECK_FILES) \
		-Wunmatched_returns \
		-Werror_handling
else
	@$(REBAR) dialyzer
endif

check-eunit: eunit
ifeq ($(REBAR_VSN),2)
	dialyzer --verbose --no_check_plt --no_native --fullpath \
		$(CHECK_EUNIT_FILES) \
		-Wunmatched_returns \
		-Werror_handling
else
	@$(REBAR) dialyzer
endif

doc:
ifeq ($(REBAR_VSN),2)
	@$(REBAR) doc skip_deps=true
else
	@$(REBAR) edoc
endif

# The "install" step for Travis
travis-install:
ifeq ($(FORCE_REBAR2),true)
	rebar get-deps
else
	wget https://s3.amazonaws.com/rebar3/rebar3
	chmod a+x rebar3
endif
