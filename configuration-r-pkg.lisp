;;;; configuration-r-pkg.lisp

(defpackage #:configuration-r
  (:use #:cl #:xlog)
  (:import-from #:uiop
                #:pathname-equal
                #:pathname-parent-directory-pathname
                #:ensure-directory-pathname
                #:getcwd
                #:truename
                #:ensure-pathname
                #:pathname-directory-pathname
                #:user-homedir-pathname)
  (:export #:find-file-in-parent
           #:get-config
           #:get-config1))
