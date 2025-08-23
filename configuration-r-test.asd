;;;; configuration-r-test.asd

(asdf:defsystem #:configuration-r-test
  :description "Tests for the configuration-r library"
  :author "wgl@ciex-security.com"
  :license  "GPL"
  :version "1.2.4"
  :serial t
  :depends-on (#:configuration-r #:fiveam)
  :components ((:file "configuration-r-test-pkg")
               (:module "tests"
                :components ((:file "main-config-r-test"))))
  :perform (asdf:test-op (op c)
             (unwind-protect
                  (progn
                    ;; Set this to true to see the test output
                    (setf fiveam:*test-dribble* t)
                    (uiop:symbol-call :configuration-r-test :create-test-config-files)
                    (uiop:symbol-call :fiveam :run! :configuration-r-tests))
               (uiop:symbol-call :configuration-r-test :cleanup-test-config-files))))
