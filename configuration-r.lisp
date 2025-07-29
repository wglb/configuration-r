;;;; configuration-r.lisp

(declaim (optimize (speed 0) (safety 3) (space 0) (debug 3)) )

(in-package #:configuration-r)

(defun find-file-in-parent0 (pn target)
  (if pn
      (let ((tpn (merge-pathnames target pn)))
        (debugc 5 (xlogntf "ffip: target ~s pn ~s" target pn))
        (if (probe-file tpn)
            tpn
            (let ((npn (truename (uiop:pathname-parent-directory-pathname pn))))
              (if (equal npn pn)
                  nil
                  (find-file-in-parent0 npn target)))))))

(defun find-file-in-parent (pn target)
  "Account for being in an emacs volume that won't cd .. to root of file system"
  (let ((ans (find-file-in-parent0 pn target)))
	(debugc 5 (xlogntf "probe says ~a" ans))
	(unless ans
	  (xlogntf "gotta null")
	  (setf ans (find-file-in-parent0  "~/." target))
	  (debugc 5 (xlogntf "Now got ans ~a" ans)))
	ans))

(defparameter *config* -1)

(defun get-config0 (dir-components fn ty property &key (debug nil) )
  "look in parent, recursiveley. If a mounted /Volume on mac os-x, it won't go to home directory. "
  (if debug (xlogntf "gc0: dir-components ~s fn ~s ty ~s prop ~s" dir-components fn ty property))
  (if dir-components
	  (let* ((fnx (make-pathname :directory dir-components :name fn :type ty)) ;; Use dir-components directly
			  (*print-pretty* nil)
			  ;; Ensure dfnx is always a list of components for recursive calls
			  (dfnx (pathname-directory (namestring fnx)))
			  (pf (probe-file fnx)))
		(if debug (xlogntf "gc0: pf is ~s fnx is ~s~%    dfnx is ~s" pf fnx dfnx))
		(cond (pf
			   (with-open-file (fi pf :direction :input)
				 (let* ((result (read fi))
						(ans (assoc property result)))
				   (if debug (xlogntf "gc0: config file ~s ~%    assoc ~s ~%    pf ~s" result ans pf))
				   (cond  ((not ans)
                           (if debug (xlogntf "gc0: property ~s not found" property))
					       (get-config0 (butlast dir-components) fn ty  property)) ;; Use butlast on dir-components

                          (t (let ((res (cdr ans)))
						       (if debug
							       (xlogntf "gc0:prop ans ~s val ~s dir-components ~s" property res dfnx))
                               (values res fnx)))))))
			  (t (if debug (xlogntf "gc0: no file in ~s" fnx))
				 (let ((ndir (butlast dir-components))) ;; Use butlast on dir-components
				   (multiple-value-bind (r f)
					   (get-config0 ndir fn ty property)
					 (if debug (xlogntf "gco: going to parent: dfnx is ~s butlast is ~s" dfnx (butlast dfnx) ))
					 (if debug (xlogntf "gc0: prop ~s is ~s in file ~s" property r f))
					 (values r f))))))
	  nil))

(defun get-config (filename property &key  (dir nil) (debug nil))
  "get-config answers the property found in the file named 'fn'.
   filename must be a pathname from 'make-pathname or 'merge-pathnames
   If fn is not in the specified directory, or if the property is not found in that file, get-config will look in the parent.
    Recursively.
    Returns values of (result filename)"
  (let* ((initial-dir-components (if dir
                                     (pathname-directory (namestring dir))
                                     (pathname-directory *default-pathname-defaults*)))
		 (fn (pathname-name filename))
		 (ty (pathname-type filename)))
	(if debug
		(xlogntf "gc: fn ~s prop ~s dir ~s~%    initial-dir-components ~s" filename property dir initial-dir-components))
	(handler-case
		(get-config0 initial-dir-components fn ty property :debug debug)
	  (error (e)
		(xlogntf "get-config: error ~e in getting ~a from ~a" e property filename)
        nil))))

(defun get-config1 (filename property &key (debug nil))
  "TODO -- this is making errors building up the pathname. Most noteable if passed an absolute pathname  "
  ;; Simplified the directory calculation to avoid the complex make-pathname/append logic
  ;; and ensure 'dir-components' is always a list of components.
  (let* ((dir-components (pathname-directory filename)) ;; This should give a list like (:absolute "a" "b")
         (fn (pathname-name filename))
         (ty (pathname-type filename))
         (ans (get-config0 dir-components fn ty property :debug debug)))
    (if debug
        (xlogntf "gc1: filename ~s fn ~s property ~s val ~s" filename fn property ans))
    ans))
