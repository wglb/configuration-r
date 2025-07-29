;;;; configuration-r-test.asd

(asdf:defsystem #:configuration-r-test
  :description "Tests for the configuration-r library"
  :author "wgl@ciex-security.com"
  :license  "GPL"
  :version "0.1.0"
  :serial t
  :depends-on (#:configuration-r #:fiveam)
  :components ((:file "configuration-r-test-pkg") ;; Added the new package file
               (:module "tests"
                :components ((:file "main"))))
  :perform (asdf:test-op (op c)
             ;; Explicitly call setup, run tests, then teardown
             ;; Use unwind-protect to ensure cleanup even if tests fail
             (unwind-protect
                  (progn
                    (uiop:symbol-call :configuration-r-test :create-test-config-files)
                    (uiop:symbol-call :fiveam :run! :configuration-r-tests))
               (uiop:symbol-call :configuration-r-test :cleanup-test-config-files))))

