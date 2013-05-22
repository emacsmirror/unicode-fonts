EMACS=emacs
# EMACS=/Applications/Emacs.app/Contents/MacOS/Emacs
# EMACS=/Applications/Emacs23.app/Contents/MacOS/Emacs
# EMACS=/Applications/Aquamacs.app/Contents/MacOS/Aquamacs
# EMACS=/Applications/Macmacs.app/Contents/MacOS/Emacs
# EMACS=/usr/local/bin/emacs
# EMACS=/opt/local/bin/emacs
# EMACS=/usr/bin/emacs

INTERACTIVE_EMACS=/usr/local/bin/emacs
# can't find an OS X variant that works correctly for interactive tests:
# INTERACTIVE_EMACS=open -a Emacs.app --new --args
# INTERACTIVE_EMACS=/Applications/Emacs.app/Contents/MacOS/Emacs
# INTERACTIVE_EMACS=/Applications/Emacs.app/Contents/MacOS/bin/emacs

RESOLVED_EMACS=$(shell readlink `which $(EMACS)` || echo "$(EMACS)")
RESOLVED_INTERACTIVE_EMACS=$(shell readlink `which "$(INTERACTIVE_EMACS)"` || echo "$(INTERACTIVE_EMACS)")

EMACS_CLEAN=-Q
EMACS_BATCH=$(EMACS_CLEAN) --batch
# TESTS can be overridden to specify a subset of tests
TESTS=
WIKI_USERNAME=roland.walker

CURL=curl --silent
EDITOR=runemacs -no_wait
WORK_DIR=$(shell pwd)
PACKAGE_NAME=$(shell basename $(WORK_DIR))
PACKAGE_VERSION=$(shell perl -ne 'print "$$1\n" if m{^;+ *Version: *(\S+)}' $(PACKAGE_NAME).el)
AUTOLOADS_FILE=$(PACKAGE_NAME)-autoloads.el
TRAVIS_FILE=.travis.yml
TEST_DIR=ert-tests
TEST_DATADIR=test_output
TEST_DEP_1=ert
TEST_DEP_1_STABLE_URL=http://bzr.savannah.gnu.org/lh/emacs/emacs-24/download/head:/ert.el-20110112160650-056hnl9qhpjvjicy-2/ert.el
TEST_DEP_1_LATEST_URL=https://raw.github.com/emacsmirror/emacs/master/lisp/emacs-lisp/ert.el
TEST_DEP_2=pcache
TEST_DEP_2_STABLE_URL=https://raw.github.com/sigma/pcache/fa8f863546e2e8f2fc0a70f5cc766a7f584e01b6/pcache.el
TEST_DEP_2_LATEST_URL=https://raw.github.com/sigma/pcache/master/pcache.el
TEST_DEP_3=list-utils
TEST_DEP_3_STABLE_URL=https://raw.github.com/rolandwalker/list-utils/a34f1d5c0be3faadd76680509e958797a60c0a41/list-utils.el
TEST_DEP_3_LATEST_URL=https://raw.github.com/rolandwalker/list-utils/master/list-utils.el
TEST_DEP_4=persistent-soft
TEST_DEP_4_STABLE_URL=https://raw.github.com/rolandwalker/persistent-soft/de0d196c94a7d124d0acfa13228648d74cf2315f/persistent-soft.el
TEST_DEP_4_LATEST_URL=https://raw.github.com/rolandwalker/persistent-soft/master/persistent-soft.el
TEST_DEP_5=ucs-utils
TEST_DEP_5_STABLE_URL=https://raw.github.com/rolandwalker/ucs-utils/98578ca47b96c3505a092e40bfb6f4eb253a6827/ucs-utils.el
TEST_DEP_5_LATEST_URL=https://raw.github.com/rolandwalker/ucs-utils/master/ucs-utils.el
TEST_DEP_5a=ucs-utils-6.0-delta
TEST_DEP_5a_STABLE_URL=https://raw.github.com/rolandwalker/ucs-utils/cf38ef555fc30d9aefaf3675ebd969948b71496a/ucs-utils-6.0-delta.el
TEST_DEP_5a_LATEST_URL=https://raw.github.com/rolandwalker/ucs-utils/master/ucs-utils-6.0-delta.el
TEST_DEP_6=font-utils
TEST_DEP_6_STABLE_URL=https://raw.github.com/rolandwalker/font-utils/a7bda8bbc065480c85f0bd19cd1338627a5d3fc7/font-utils.el
TEST_DEP_6_LATEST_URL=https://raw.github.com/rolandwalker/font-utils/master/font-utils.el
TEST_DEP_7=string-utils
TEST_DEP_7_STABLE_URL=https://raw.github.com/rolandwalker/string-utils/cefb98ecf8257f69d8288929fc0425f145484452/string-utils.el
TEST_DEP_7_LATEST_URL=https://raw.github.com/rolandwalker/string-utils/master/string-utils.el
TEST_DEP_8=express
TEST_DEP_8_STABLE_URL=https://raw.github.com/rolandwalker/express/88d4c5fe5545d3889ae862d49a8f79b5ac7b3465/express.el
TEST_DEP_8_LATEST_URL=https://raw.github.com/rolandwalker/express/master/express.el

.PHONY : build dist not-dirty pkg-version downloads downloads-latest autoloads \
 test-autoloads test-travis test test-prep test-batch test-interactive         \
 test-tests clean edit run-pristine run-pristine-local upload-github           \
 upload-wiki upload-marmalade test-dep-1 test-dep-2 test-dep-3 test-dep-4      \
 test-dep-5 test-dep-5a test-dep-6 test-dep-7 test-dep-8 test-dep-9

build :
	$(RESOLVED_EMACS) $(EMACS_BATCH) --eval    \
	    "(progn                                \
	      (setq byte-compile-error-on-warn t)  \
	      (batch-byte-compile))" *.el

not-dirty :
	@git diff --quiet '$(PACKAGE_NAME).el'     || \
	 ( git --no-pager diff '$(PACKAGE_NAME).el';  \
	   echo "Uncommitted edits - do a git stash"; \
	   false )

pkg-version :
	@test -n '$(PACKAGE_VERSION)'    || \
	 ( echo "No package version"; false )

test-dep-1 :
	@cd '$(TEST_DIR)'                                               && \
	$(RESOLVED_EMACS) $(EMACS_BATCH)  -L . -L .. -l '$(TEST_DEP_1)' || \
	(echo "Can't load test dependency $(TEST_DEP_1).el, run 'make downloads' to fetch it" ; exit 1)

test-dep-2 :
	@cd '$(TEST_DIR)'                                 && \
	$(RESOLVED_EMACS) $(EMACS_BATCH)  -L . -L .. --eval  \
	    "(progn                                          \
	      (setq package-load-list '(($(TEST_DEP_2) t)))  \
	      (when (fboundp 'package-initialize)            \
	       (package-initialize))                         \
	      (require '$(TEST_DEP_2)))"                  || \
	(echo "Can't load test dependency $(TEST_DEP_2).el, run 'make downloads' to fetch it" ; exit 1)

test-dep-3 :
	@cd '$(TEST_DIR)'                                 && \
	$(RESOLVED_EMACS) $(EMACS_BATCH)  -L . -L .. --eval  \
	    "(progn                                          \
	      (setq package-load-list '(($(TEST_DEP_3) t)))  \
	      (when (fboundp 'package-initialize)            \
	       (package-initialize))                         \
	      (require '$(TEST_DEP_3)))"                  || \
	(echo "Can't load test dependency $(TEST_DEP_3).el, run 'make downloads' to fetch it" ; exit 1)

test-dep-4 :
	@cd '$(TEST_DIR)'                                 && \
	$(RESOLVED_EMACS) $(EMACS_BATCH)  -L . -L .. --eval  \
	    "(progn                                          \
	      (setq package-load-list '(($(TEST_DEP_2) t)    \
					($(TEST_DEP_3) t)    \
					($(TEST_DEP_4) t)))  \
	      (when (fboundp 'package-initialize)            \
	       (package-initialize))                         \
	      (require '$(TEST_DEP_4)))"                  || \
	(echo "Can't load test dependency $(TEST_DEP_4).el, run 'make downloads' to fetch it" ; exit 1)

test-dep-5 :
	@cd '$(TEST_DIR)'                                 && \
	$(RESOLVED_EMACS) $(EMACS_BATCH)  -L . -L .. --eval  \
	    "(progn                                          \
	      (setq package-load-list '(($(TEST_DEP_2) t)    \
					($(TEST_DEP_3) t)    \
					($(TEST_DEP_4) t)    \
					($(TEST_DEP_5) t)))  \
	      (when (fboundp 'package-initialize)            \
	       (package-initialize))                         \
	      (require '$(TEST_DEP_5)))"                  || \
	(echo "Can't load test dependency $(TEST_DEP_5).el, run 'make downloads' to fetch it" ; exit 1)

test-dep-6 :
	@cd '$(TEST_DIR)'                                 && \
	$(RESOLVED_EMACS) $(EMACS_BATCH)  -L . -L .. --eval  \
	    "(progn                                          \
	      (setq package-load-list '(($(TEST_DEP_2) t)    \
					($(TEST_DEP_3) t)    \
					($(TEST_DEP_4) t)    \
					($(TEST_DEP_6) t)))  \
	      (when (fboundp 'package-initialize)            \
	       (package-initialize))                         \
	      (require '$(TEST_DEP_6)))"                  || \
	(echo "Can't load test dependency $(TEST_DEP_6).el, run 'make downloads' to fetch it" ; exit 1)

test-dep-7 :
	@cd '$(TEST_DIR)'                                 && \
	$(RESOLVED_EMACS) $(EMACS_BATCH)  -L . -L .. --eval  \
	    "(progn                                          \
	      (setq package-load-list '(($(TEST_DEP_3) t)    \
	                                ($(TEST_DEP_7) t)))  \
	      (when (fboundp 'package-initialize)            \
	       (package-initialize))                         \
	      (require '$(TEST_DEP_7)))"                  || \
	(echo "Can't load test dependency $(TEST_DEP_7).el, run 'make downloads' to fetch it" ; exit 1)

test-dep-8 :
	@cd '$(TEST_DIR)'                                 && \
	$(RESOLVED_EMACS) $(EMACS_BATCH)  -L . -L .. --eval  \
	    "(progn                                          \
	      (setq package-load-list '(($(TEST_DEP_3) t)    \
	                                ($(TEST_DEP_7) t)    \
	                                ($(TEST_DEP_8) t)))  \
	      (when (fboundp 'package-initialize)            \
	       (package-initialize))                         \
	      (require '$(TEST_DEP_8)))"                  || \
	(echo "Can't load test dependency $(TEST_DEP_8).el, run 'make downloads' to fetch it" ; exit 1)

downloads :
	$(CURL) '$(TEST_DEP_1_STABLE_URL)'  > '$(TEST_DIR)/$(TEST_DEP_1).el'
	$(CURL) '$(TEST_DEP_2_STABLE_URL)'  > '$(TEST_DIR)/$(TEST_DEP_2).el'
	$(CURL) '$(TEST_DEP_3_STABLE_URL)'  > '$(TEST_DIR)/$(TEST_DEP_3).el'
	$(CURL) '$(TEST_DEP_4_STABLE_URL)'  > '$(TEST_DIR)/$(TEST_DEP_4).el'
	$(CURL) '$(TEST_DEP_5_STABLE_URL)'  > '$(TEST_DIR)/$(TEST_DEP_5).el'
	$(CURL) '$(TEST_DEP_5a_STABLE_URL)' > '$(TEST_DIR)/$(TEST_DEP_5a).el'
	$(CURL) '$(TEST_DEP_6_STABLE_URL)'  > '$(TEST_DIR)/$(TEST_DEP_6).el'
	$(CURL) '$(TEST_DEP_7_STABLE_URL)'  > '$(TEST_DIR)/$(TEST_DEP_7).el'
	$(CURL) '$(TEST_DEP_8_STABLE_URL)'  > '$(TEST_DIR)/$(TEST_DEP_8).el'

downloads-latest :
	$(CURL) '$(TEST_DEP_1_LATEST_URL)'  > '$(TEST_DIR)/$(TEST_DEP_1).el'
	$(CURL) '$(TEST_DEP_2_LATEST_URL)'  > '$(TEST_DIR)/$(TEST_DEP_2).el'
	$(CURL) '$(TEST_DEP_3_LATEST_URL)'  > '$(TEST_DIR)/$(TEST_DEP_3).el'
	$(CURL) '$(TEST_DEP_4_LATEST_URL)'  > '$(TEST_DIR)/$(TEST_DEP_4).el'
	$(CURL) '$(TEST_DEP_5_LATEST_URL)'  > '$(TEST_DIR)/$(TEST_DEP_5).el'
	$(CURL) '$(TEST_DEP_5a_LATEST_URL)' > '$(TEST_DIR)/$(TEST_DEP_5a).el'
	$(CURL) '$(TEST_DEP_6_LATEST_URL)'  > '$(TEST_DIR)/$(TEST_DEP_6).el'
	$(CURL) '$(TEST_DEP_7_LATEST_URL)'  > '$(TEST_DIR)/$(TEST_DEP_7).el'
	$(CURL) '$(TEST_DEP_8_LATEST_URL)'  > '$(TEST_DIR)/$(TEST_DEP_8).el'

autoloads :
	$(RESOLVED_EMACS) $(EMACS_BATCH) --eval              \
	    "(progn                                          \
	      (setq generated-autoload-file \"$(WORK_DIR)/$(AUTOLOADS_FILE)\") \
	      (update-directory-autoloads \"$(WORK_DIR)\"))"

test-autoloads : autoloads
	@$(RESOLVED_EMACS) $(EMACS_BATCH) -L . -l './$(AUTOLOADS_FILE)' || \
	 ( echo "failed to load autoloads: $(AUTOLOADS_FILE)" && false )

test-travis :
	@if test -z "$$TRAVIS" && test -e '$(TRAVIS_FILE)'; then travis-lint '$(TRAVIS_FILE)'; fi

test-tests :
	@perl -ne 'if (m/^\s*\(\s*ert-deftest\s*(\S+)/) {die "$$1 test name duplicated in $$ARGV\n" if $$dupes{$$1}++}' '$(TEST_DIR)/'*-test.el

test-prep : build test-dep-1 test-dep-2 test-dep-3 test-dep-4 test-dep-5 test-dep-6 test-dep-7 test-dep-8 test-autoloads test-travis test-tests

test-batch :
	@cd '$(TEST_DIR)'                                 && \
	(for test_lib in *-test.el; do                       \
	   $(RESOLVED_EMACS) $(EMACS_BATCH) -L . -L .. -l cl \
	   -l '$(TEST_DEP_1)' -l "$$test_lib" --eval         \
	    "(flet ((ert--print-backtrace (&rest args)       \
	      (insert \"no backtrace in batch mode\")))      \
	       (ert-run-tests-batch-and-exit '(and \"$(TESTS)\" (not (tag :interactive)))))" || exit 1; \
	done)

test-interactive : test-prep
	@cd '$(TEST_DIR)'                                             && \
	(for test_lib in *-test.el; do                                   \
	    $(RESOLVED_INTERACTIVE_EMACS) $(EMACS_CLEAN) --eval          \
	    "(progn                                                      \
	      (cd \"$(WORK_DIR)/$(TEST_DIR)\")                           \
	      (setq dired-use-ls-dired nil)                              \
	      (setq frame-title-format \"TEST SESSION $$test_lib\")      \
	      (setq enable-local-variables :safe))"                      \
	    -L . -L .. -l cl -l '$(TEST_DEP_1)' -l "$$test_lib"          \
	    --visit "$$test_lib" --eval                                  \
	    "(progn                                                      \
	      (when (> (length \"$(TESTS)\") 0)                          \
	       (push \"\\\"$(TESTS)\\\"\" ert--selector-history))        \
	      (setq buffer-read-only t)                                  \
	      (setq cursor-in-echo-area t)                               \
	      (call-interactively 'ert-run-tests-interactively)          \
	      (ding)                                                     \
	      (when (y-or-n-p \"PRESS Y TO QUIT THIS TEST SESSION\")     \
	       (with-current-buffer \"*ert*\"                            \
	        (kill-emacs                                              \
	         (if (re-search-forward \"^Failed:[^\\n]+unexpected\" 500 t) 1 0)))))" || exit 1; \
	done)

test : test-prep test-batch

run-pristine :
	@cd '$(TEST_DIR)'                                              && \
	$(RESOLVED_EMACS) $(EMACS_CLEAN) --eval                           \
	 "(progn                                                          \
	   (setq package-enable-at-startup nil)                           \
	   (setq package-load-list '(($(TEST_DEP_2) t)                    \
				     ($(TEST_DEP_3) t)                    \
				     ($(TEST_DEP_4) t)                    \
				     ($(TEST_DEP_5) t)                    \
				     ($(TEST_DEP_6) t)                    \
				     ($(TEST_DEP_7) t)))                  \
	   (when (fboundp 'package-initialize)                            \
	    (package-initialize))                                         \
	   (cd \"$(WORK_DIR)/$(TEST_DIR)\")                               \
	   (setq dired-use-ls-dired nil)                                  \
	   (setq frame-title-format \"PRISTINE SESSION $(PACKAGE_NAME)\") \
	   (setq enable-local-variables :safe))"                          \
	 -L .. -l '$(PACKAGE_NAME)' .

run-pristine-local :
	@cd '$(TEST_DIR)'                                              && \
	$(RESOLVED_EMACS) $(EMACS_CLEAN) --eval                           \
	 "(progn                                                          \
	   (cd \"$(WORK_DIR)/$(TEST_DIR)\")                               \
	   (setq dired-use-ls-dired nil)                                  \
	   (setq frame-title-format \"PRISTINE-LOCAL SESSION $(PACKAGE_NAME)\") \
	   (setq enable-local-variables :safe))"                          \
	 -L . -L .. -l '$(PACKAGE_NAME)' .

clean :
	@rm -f '$(AUTOLOADS_FILE)' *.elc *~ */*.elc */*~ .DS_Store */.DS_Store *.bak */*.bak && \
	cd '$(TEST_DIR)'                                                                     && \
	rm -f './$(TEST_DEP_1).el' './$(TEST_DEP_2).el' './$(TEST_DEP_3).el' './$(TEST_DEP_4).el' './$(TEST_DEP_5a).el'   \
	      './$(TEST_DEP_5).el' './$(TEST_DEP_6).el' './$(TEST_DEP_7).el' './$(TEST_DEP_8).el' './$(TEST_DEP_9).el' && \
	if test -n '$(TEST_DATADIR)'; then rm -rf './$(TEST_DATADIR)'; fi

edit :
	@$(EDITOR) `git ls-files`

upload-github :
	@git push origin master

upload-wiki : not-dirty
	@$(RESOLVED_EMACS) $(EMACS_BATCH) --eval          \
	 "(progn                                          \
	   (setq package-load-list '((yaoddmuse t)))      \
	   (when (fboundp 'package-initialize)            \
	    (package-initialize))                         \
	   (require 'yaoddmuse)                           \
	   (setq yaoddmuse-username \"$(WIKI_USERNAME)\") \
	   (yaoddmuse-post-file                           \
	    \"$(PACKAGE_NAME).el\"                        \
	    yaoddmuse-default-wiki                        \
	    \"$(PACKAGE_NAME).el\"                        \
	    \"updated version\") \
	   (sleep-for 5))"
