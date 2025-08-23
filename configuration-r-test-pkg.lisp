;;;; configuration-r-test-pkg.lisp

(defpackage #:configuration-r-test
  (:use #:cl #:fiveam #:configuration-r #:uiop)
  (:export #:create-test-config-files
           #:cleanup-test-config-files
           #:run-tests-with-cleanup
           #:configuration-r-tests)) ;; <- This is the fix

